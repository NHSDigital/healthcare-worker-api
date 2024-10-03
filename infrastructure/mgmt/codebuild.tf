resource "aws_iam_role" "codebuild_role" {
  name = "CodeBuildRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "codebuild_agent_policy" {
  name = "codebuild_agent_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "s3:PutObject",
        "Resource" : "*"
      },
      {
        "Effect": "Allow",
        "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        "Resource": [
          "arn:aws:logs:eu-west-2:${local.account_id}:log-group:/aws/codebuild/hcw-api-build:log-stream",
          "arn:aws:logs:eu-west-2:${local.account_id}:log-group:/aws/codebuild/hcw-api-build:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_attach_policy" {
  role = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_agent_policy.arn
}

resource "aws_codebuild_project" "hcw-api-build" {
  name = "hcw-api-build"
  service_role = aws_iam_role.codebuild_role.arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type         = "LINUX_CONTAINER"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type = "GITHUB"
    location = "https://github.com/NHSDigital/healthcare-worker-api"

    git_submodules_config {
      fetch_submodules = false
    }
  }
}

