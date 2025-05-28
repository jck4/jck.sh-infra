terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "jcksh-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "jcksh-terraform-state"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "infra"
  }
}

data "aws_route53_zone" "this" {
  name         = "jck.sh"
  private_zone = false
}

resource "aws_lightsail_instance" "this" {
  name              = "jck.sh"
  availability_zone = "us-east-1a"
  blueprint_id      = "ubuntu_24_04"
  bundle_id         = "medium_3_0"

  key_pair_name = "jck.sh-key"
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "www.jck.sh"
  type    = "A"
  ttl     = 300
  records = [aws_lightsail_instance.this.public_ip_address]
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "jck.sh"
  type    = "A"
  ttl     = 300
  records = [aws_lightsail_instance.this.public_ip_address]
}

resource "aws_route53_record" "dnd" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "dnd.jck.sh"
  type    = "A"
  ttl     = 300
  records = [aws_lightsail_instance.this.public_ip_address]
}
resource "aws_route53_record" "monitoring" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "monitoring.jck.sh"
  type    = "A"
  ttl     = 300
  records = [aws_lightsail_instance.this.public_ip_address]
}