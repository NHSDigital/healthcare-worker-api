resource "aws_api_gateway_rest_api" "api" {
  name = "hcw-api-${var.env}"
  body = file("${path.module}/../../../specification/healthcare-worker-api.yaml")

  put_rest_api_mode = "merge"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
