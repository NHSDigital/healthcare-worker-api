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
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "535002889321"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "fetch_build_artifacts" {
  name = "fetch-build-artifacts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "s3:Get*",
        "Resource" : ["arn:aws:s3:::nhse-iam-hcw-build-artifacts-dev/*"]
      },
      {
        "Effect" : "Allow",
        "Action" : "s3:ListBucket",
        "Resource" : ["arn:aws:s3:::nhse-iam-hcw-build-artifacts-dev"]
      },
      {
        "Effect": "Allow",
        "Action": [
           "kms:DescribeKey",
           "kms:GenerateDataKey*",
           "kms:Encrypt",
           "kms:ReEncrypt*",
           "kms:Decrypt"
          ],
        "Resource": [
           "arn:aws:kms:eu-west-2:535002889321:key/abd1c7ca-8423-4fc0-9b11-f9af494c2cac"
          ]
      }
    ]
  })
}

# The deployment job needs a lot of permissions because it's running terraform, which could be modifying lots of different resources
# TODO: Think about if we want to be more restrictive, probably okay with restrictions on branch pushes
data "aws_iam_policy" "power_user_policy" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_deploy_job_attach_policy" {
  role       = aws_iam_role.codebuild_deploy_job_role.name
  policy_arn = data.aws_iam_policy.power_user_policy.arn
}

resource "aws_iam_role_policy_attachment" "build_artifacts_attach_policy" {
  role       = aws_iam_role.codebuild_deploy_job_role.name
  policy_arn = aws_iam_policy.fetch_build_artifacts.arn
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

resource "aws_codebuild_project" "hcw-api-destroy-pr-env" {
  name         = "hcw-api-destroy-pr-env"
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
    buildspec = "buildspecs/destroy-pr-env.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }
}

