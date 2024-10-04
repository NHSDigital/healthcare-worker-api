terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    encrypt = true
    bucket = "nhse-iam-hcw-terraform-state"
    dynamodb_table = "terraform-state-lock"
    key = "terraform.tfstate"
    region = "eu-west-2"
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

# TODO: Need to think of a cleverer way of doing this. We only want one over all the environments, so maybe we do
# need a dedicated management account?
module "terraform_state" {
  source = "./terraform_state"

  count = local.env == "mgmt" ? 1 : 0
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
