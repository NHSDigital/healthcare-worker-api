data "aws_s3_bucket" "app_deployment" {
  bucket = "nhse-iam-hcw-build-artifacts-dev"
}

data "aws_s3_object" "app_deployment_zip" {
  bucket = data.aws_s3_bucket.app_deployment.id
  key    = var.s3_filename
}

resource "aws_lambda_function" "hcw-app" {
  function_name = "hcw-app-${var.env}"
  role          = aws_iam_role.lambda-app-role.arn

  runtime = "python3.12"

  s3_bucket = data.aws_s3_bucket.app_deployment.id
  s3_key    = var.s3_filename
  handler   = "main.lambda_handler"

  source_code_hash = data.aws_s3_object.app_deployment_zip.etag

  publish = true
}

resource "aws_iam_role" "lambda-app-role" {
  name = "lambda_app_role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = "Currently live version for this environment"
  function_name    = aws_lambda_function.hcw-app.arn
  function_version = aws_lambda_function.hcw-app.version
}
