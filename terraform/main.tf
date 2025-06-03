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

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# Create policies first
module "iam" {
  source = "./modules/iam"
}

module "s3" {
  source = "./modules/s3"
}

module "launch_templates" {
  source = "./modules/launch_templates"
}

module "lambda" {
  source = "./modules/lambda"
  lambda_role_arn = module.iam.lambda_role_arn
}
