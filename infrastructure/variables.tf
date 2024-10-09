variable "account" {
  type = string
}

variable "apim_environment" {
  type = string
}

variable "app_s3_filename" {
  type    = string
  default = "hcw-api-build.zip"
}

locals {
  env = terraform.workspace
}
