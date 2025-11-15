# https://registry.terraform.io/providers/hashicorp/aws/latest/docs

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket               = "recipe-379738700125-django-api"
    key                  = "deploy-key"
    region               = "us-east-1"
    use_lockfile         = true # https://developer.hashicorp.com/terraform/language/backend/s3s
    encrypt              = false
    workspace_key_prefix = "environ-ws"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project_name
      Contact     = var.contact
      ManagedBy   = "terraform/deploy"
    }
  }
}

locals {
  prefix = "${var.project_name}-${terraform.workspace}"
}

data "aws_region" "current" {}