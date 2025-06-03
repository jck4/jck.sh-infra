import boto3
import json
import logging
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client('ec2')
ec2_resource = boto3.resource('ec2')
ssm = boto3.client('ssm')


def get_cloudflare_api_token():
    param = ssm.get_parameter(Name='cloudfront_key', WithDecryption=True)
    return param['Parameter']['Value']


def get_latest_launch_template():
    paginator = ec2.get_paginator('describe_launch_templates')
    templates = []

    for page in paginator.paginate():
        for tmpl in page['LaunchTemplates']:
            if tmpl['LaunchTemplateName'].startswith('foundry-spot-'):
                templates.append(tmpl)

    if not templates:
        raise Exception("No launch templates found with prefix 'foundry-spot-'")

    latest = sorted(templates, key=lambda x: x['CreateTime'], reverse=True)[0]
    return latest['LaunchTemplateId'], latest['LatestVersionNumber']


def instance_already_running():
    filters = [
        {'Name': 'tag:Name', 'Values': ['foundryvtt-spot']},
        {'Name': 'instance-state-name', 'Values': ['pending', 'running']}
    ]
    reservations = ec2.describe_instances(Filters=filters).get('Reservations', [])
    instances = [i for r in reservations for i in r['Instances']]
    return instances[0] if instances else None


def get_volume_by_name(name="foundryvtt-data"):
    filters = [
        {'Name': 'tag:Name', 'Values': [name]},
        {'Name': 'status', 'Values': ['available']}
    ]
    volumes = ec2.describe_volumes(Filters=filters)['Volumes']
    if not volumes:
        raise Exception(f"No available EBS volume found with tag Name={name}")
    return volumes[0]['VolumeId']


def update_cloudflare_dns(subdomain, zone_name, ip_address, api_token):
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json"
    }

    # Get Zone ID
    zone_resp = requests.get(
        f"https://api.cloudflare.com/client/v4/zones?name={zone_name}",
        headers=headers
    )
    zone_resp.raise_for_status()
    zone_id = zone_resp.json()["result"][0]["id"]

    fqdn = f"{subdomain}.{zone_name}"

    # Get existing record ID (if exists)
    record_resp = requests.get(
        f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records?type=A&name={fqdn}",
        headers=headers
    )
    record_resp.raise_for_status()
    records = record_resp.json()["result"]
    record_id = records[0]["id"] if records else None

    payload = {
        "type": "A",
        "name": fqdn,
        "content": ip_address,
        "ttl": 60,
        "proxied": False
    }

    if record_id:
        update_resp = requests.put(
            f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{record_id}",
            headers=headers,
            json=payload
        )
        update_resp.raise_for_status()
        return update_resp.json()
    else:
        create_resp = requests.post(
            f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records",
            headers=headers,
            json=payload
        )
        create_resp.raise_for_status()
        return create_resp.json()


def lambda_handler(event, context):
    try:
        cloudflare_token = get_cloudflare_api_token()

        launch_template_id, version = get_latest_launch_template()
        logger.info(f"Using launch template {launch_template_id}, version {version}")

        existing_instance = instance_already_running()
        if existing_instance:
            instance_id = existing_instance['InstanceId']
            logger.info(f"Found existing instance: {instance_id}")
            instance = ec2_resource.Instance(instance_id)
            instance.load()
            if not instance.public_ip_address:
                logger.info("Waiting for instance to enter 'running' state...")
                instance.wait_until_running()
                instance.load()
            public_ip = instance.public_ip_address

            update_cloudflare_dns("dnd", "jck.sh", public_ip, cloudflare_token)

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Existing instance reused and DNS updated',
                    'instanceId': instance_id,
                    'publicIp': public_ip
                })
            }

        # Launch new spot instance
        response = ec2.run_instances(
            LaunchTemplate={
                'LaunchTemplateId': launch_template_id,
                'Version': str(version)
            },
            InstanceMarketOptions={
                'MarketType': 'spot',
                'SpotOptions': {
                    'SpotInstanceType': 'one-time'
                }
            },
            InstanceType='t3.micro',
            MinCount=1,
            MaxCount=1
        )

        instance_id = response['Instances'][0]['InstanceId']
        logger.info(f"Spot instance launched: {instance_id}")

        instance = ec2_resource.Instance(instance_id)
        logger.info("Waiting for new instance to enter 'running' state...")
        instance.wait_until_running()
        instance.load()

        # Attach the existing EBS volume
        volume_id = get_volume_by_name("foundryvtt-data")
        logger.info(f"Attaching volume {volume_id} to instance {instance_id}...")
        ec2.attach_volume(
            VolumeId=volume_id,
            InstanceId=instance_id,
            Device="/dev/xvdf"
        )

        public_ip = instance.public_ip_address
        logger.info(f"Instance public IP: {public_ip}")

        # Update Cloudflare DNS
        dns_result = update_cloudflare_dns("dnd", "jck.sh", public_ip, cloudflare_token)
        logger.info(f"Cloudflare DNS update: {json.dumps(dns_result)}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Spot instance launched, volume attached, DNS updated',
                'instanceId': instance_id,
                'publicIp': public_ip,
                'volumeId': volume_id,
                'launchTemplateId': launch_template_id,
                'version': version
            })
        }

    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
