resource "aws_iam_role" "codedeploy" {
  name = "CodeDeployRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_policy" "codedeploy_policy" {
  name = "codedeploy_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : ["lambda:*"],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy.id
  policy_arn = aws_iam_policy.codedeploy_policy.arn
}

resource "aws_codedeploy_app" "hcw-api" {
  name             = "hcw-api-${var.account}"
  compute_platform = "Lambda"
}

resource "aws_codedeploy_deployment_group" "hcw-api" {
  app_name              = aws_codedeploy_app.hcw-api.name
  deployment_group_name = "hcw-api-${var.account}"
  service_role_arn      = aws_iam_role.codedeploy.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"
}

