terraform {
  required_version = ">= 1.0"

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


data "aws_route53_zone" "this" {
  name         = "jck.sh"
  private_zone = false
}


resource "aws_lightsail_key_pair" "this" {
  name       = "jck.sh-key"
  public_key = file("/home/jck/.ssh/id_ed25519.pub")
}


resource "aws_lightsail_instance" "this" {
  name              = "jck.sh"
  availability_zone = "us-east-1a"
  blueprint_id      = "ubuntu_24_04"
  bundle_id         = "medium_3_0"

  key_pair_name = aws_lightsail_key_pair.this.name
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