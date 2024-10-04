terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Environment = local.env
      Account     = var.account
    }
  }
}

module "management" {
  source  = "./mgmt"
  account = var.account

  count = local.env == "mgmt" ? 1 : 0
}

module "app" {
  source  = "./modules/hcw-api"
  env     = local.env
  account = var.account

  count = local.env != "mgmt" ? 1 : 0
}
