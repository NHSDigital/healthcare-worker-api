variable "account" {
  type = string
}

variable "apim_environment" {
  type = string
}

variable "app_s3_filename" {
  type    = string
  default = "f8a2fb5ccc0d3b305ca4f3de1a6a775732a6f684.zip"
}

locals {
  env = terraform.workspace
}
