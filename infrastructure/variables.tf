variable "account" {
  type = string
}

variable "app_s3_filename" {
  type    = string
  default = "c0130d95-d26d-4f26-9486-e2dd745e68a0/hcw-api-build.zip"
}

locals {
  env = terraform.workspace
}
