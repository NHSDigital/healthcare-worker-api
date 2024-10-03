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
}

module "management" {
  source = "./mgmt"
  account = var.account

  count = terraform.workspace == "mgmt" ? 1 : 0
}

module "app" {
  source = "./modules/hcw-api"
  env = terraform.workspace
  account = var.account

  count = terraform.workspace != "mgmt" ? 1 : 0
}
