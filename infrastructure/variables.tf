variable "account" {
  type = string
}

locals {
  env = terraform.workspace
}
