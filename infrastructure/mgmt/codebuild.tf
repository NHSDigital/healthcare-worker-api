data "aws_codestarconnections_connection" "github_connection" {
  name = "Github"
}

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
        "Effect" : "Allow",
        "Action" : ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.account_id}:log-group:/aws/codebuild/hcw-api-build:log-stream",
          "arn:aws:logs:eu-west-2:${local.account_id}:log-group:/aws/codebuild/hcw-api-build:log-stream:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : ["s3:GetObject"],
        "Resource" : [
          aws_s3_bucket.build_artifacts.arn,
          "${aws_s3_bucket.build_artifacts.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_attach_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_agent_policy.arn
}

resource "aws_codebuild_project" "hcw-api-build" {
  name         = "hcw-api-build"
  service_role = aws_iam_role.codebuild_role.arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"
  }

  artifacts {
    type = "S3"

    artifact_identifier = "hcw-api-app"
    location            = "nhse-iam-hcw-build-artifacts-dev"

    name           = "hcw-api-build.zip"
    namespace_type = "BUILD_ID"
    packaging      = "ZIP"
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/NHSDigital/healthcare-worker-api"
    buildspec = "buildspecs/build.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }
}

