resource "aws_lambda_function" "hcw-app" {
  function_name = "hcw-app-${var.env}"
  role          = aws_iam_role.lambda-app-role.arn

  runtime = "python3.12"

  s3_bucket = "nhse-iam-hcw-build-artifacts-${var.account}"
  s3_key    = var.s3_filename
  handler   = "main.lambda_handler"
}

resource "aws_iam_role" "lambda-app-role" {
  name = "lambda_app_role"

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
