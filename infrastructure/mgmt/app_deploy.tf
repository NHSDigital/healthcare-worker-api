resource "aws_iam_role" "codebuild_deploy_job_role" {
  name = "CodeBuildDeployJobRole"

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

resource "aws_iam_policy" "codebuild_deploy_job_policy" {
  name = "codebuild_deploy_job_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        "Resource" : [
          "arn:aws:logs:eu-west-2:${local.account_id}:log-group:/aws/codebuild/hcw-api-deploy:log-stream",
          "arn:aws:logs:eu-west-2:${local.account_id}:log-group:/aws/codebuild/hcw-api-deploy:log-stream:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "codestar-connections:GetConnectionToken",
          "codestar-connections:GetConnection",
          "codeconnections:GetConnectionToken",
          "codeconnections:GetConnection",
          "codeconnections:UseConnection"
        ],
        "Resource" : [
          "arn:aws:codestar-connections:eu-north-1:535002889321:connection/b2b799de-0712-4567-94de-bb69a361f972",
          "arn:aws:codeconnections:eu-north-1:535002889321:connection/b2b799de-0712-4567-94de-bb69a361f972"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_deploy_job_attach_policy" {
  role       = aws_iam_role.codebuild_deploy_job_role.name
  policy_arn = aws_iam_policy.codebuild_deploy_job_policy.arn
}

resource "aws_codebuild_project" "hcw-api-deploy" {
  name         = "hcw-api-deploy"
  service_role = aws_iam_role.codebuild_deploy_job_role.arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/NHSDigital/healthcare-worker-api"
    buildspec = "buildspecs/deploy.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }
}

