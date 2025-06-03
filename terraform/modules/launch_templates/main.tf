# Get default VPC
data "aws_vpc" "default" {
  default = true
}

 # FoundryVTT EBS Volume
resource "aws_ebs_volume" "foundry" {
  availability_zone = "us-east-1a"  # Same AZ as the launch template
  type = "gp3"
  size             = 5  # 5GB volume
  tags = {
    Name    = "foundryvtt-data"
    Project = "foundryvtt"
  }
}

# Create Security Group in default VPC
resource "aws_security_group" "foundry" {
  name        = "foundry-ec2-sg"
  description = "Allow HTTP, HTTPS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "foundry-ec2-sg"
  }
}

# Pull latest Alpine AMI with Docker
data "aws_ami" "foundry" {
  most_recent = true

  filter {
    name   = "name"
    values = ["alpine-foundryvtt-*"]
  }

  owners = ["940908754875"] # me
}

# Launch Template
resource "aws_launch_template" "foundry" {
  name_prefix   = "foundry-spot-"
  image_id      = data.aws_ami.foundry.id
  instance_type = "t3.micro"
  key_name      = "jck.sh-key"

  user_data = base64encode(<<EOF
#!/bin/sh
set -eux

# Wait for EBS volume
while [ ! -e /dev/xvdf ]; do
  echo "Waiting for EBS volume..."
  sleep 2
done

# Mount EBS volume
mkdir -p /mnt/ebs
mount /dev/xvdf /mnt/ebs

# Prepare folders
mkdir -p /mnt/ebs/docker
mkdir -p /mnt/ebs/foundry_data
mkdir -p /mnt/ebs/caddy_data

mkdir -p /mnt/foundry_data /mnt/caddy_data
mount --bind /mnt/ebs/foundry_data /mnt/foundry_data
mount --bind /mnt/ebs/caddy_data /mnt/caddy_data

# Point Docker to EBS
mkdir -p /etc/docker
echo '{ "data-root": "/mnt/ebs/docker" }' > /etc/docker/daemon.json

# Start Docker
rc-service docker start

# Optional: add Docker to default services (if needed)
rc-update add docker default

# Run Compose from project dir (assumes compose yml is in /mnt/ebs)
cd /mnt/ebs
docker compose up -d

echo "EBS + Docker initialized"
EOF
  )

  # Force it into us-east-1a by specifying the subnet
  network_interfaces {
    device_index         = 0
    subnet_id            = "subnet-dc054af0"
    associate_public_ip_address = true
    security_groups      = [aws_security_group.foundry.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "foundryvtt-spot"
      Project = "foundryvtt"
    }
  }

  tag_specifications {
    resource_type = "spot-instances-request"
    tags = {
      Project = "foundryvtt"
    }
  }
}
