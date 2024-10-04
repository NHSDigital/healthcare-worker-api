resource "aws_iam_role" "app_deployment_pipeline_role" {
  name = "DeploymentPipelineRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "codepipeline_policy" {
  name = "codepipeline_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : ["codebuild:BatchGetBuilds", "codebuild:StartBuild"],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : ["s3:PutObject", "s3:GetObject"],
        "Resource" : [
          aws_s3_bucket.build_artifacts.arn,
          "${aws_s3_bucket.build_artifacts.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "codestar-connections:GetConnectionToken",
          "codestar-connections:GetConnection",
          "codeconnections:GetConnectionToken",
          "codeconnections:GetConnection",
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ],
        "Resource" : [
          "arn:aws:codestar-connections:eu-north-1:535002889321:connection/b2b799de-0712-4567-94de-bb69a361f972",
          "arn:aws:codeconnections:eu-north-1:535002889321:connection/b2b799de-0712-4567-94de-bb69a361f972"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_attach_policy" {
  role       = aws_iam_role.app_deployment_pipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_codepipeline" "app_deployment_pipeline" {
  name     = "hcw-api-deployment"
  role_arn = aws_iam_role.app_deployment_pipeline_role.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.build_artifacts.bucket
    type     = "S3"
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      pull_request {
        events = ["OPEN", "UPDATED"]
        branches {
          includes = ["*"]
        }
      }
    }
  }

  stage {
    name = "Source"

    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = "1"

      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = data.aws_codestarconnections_connection.github_connection.arn
        FullRepositoryId = "NHSDigital/healthcare-worker-api"
        BranchName       = "hcw-76-initial-deployment-pipeline"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = "hcw-api-build"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name = "S3-Upload"
      category = "Deploy"
      owner = "AWS"
      provider = "S3"
      version = "1"

      input_artifacts = ["build_output"]

      configuration = {
        BucketName = aws_s3_bucket.build_artifacts.bucket
        ObjectKey = "latest-build.zip"
        Extract = "false"
      }
    }

    action {
      name     = "Deploy"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = "hcw-api-deploy"

        EnvironmentVariables = jsonencode([
          {
            name  = "environment_name"
            value = "ianr-test"
            type  = "PLAINTEXT"
          },
          {
            name  = "account_name"
            value = "dev"
            type  = "PLAINTEXT"
          },
          {
            name  = "app_s3_filename"
            value = "latest-build.zip"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }
}

resource "aws_codepipeline_webhook" "github_webhook" {
  name = "gtihub_webhook"
  authentication = "GITHUB_HMAC"
  target_action = "Source"
  target_pipeline = aws_codepipeline.app_deployment_pipeline.name

  authentication_configuration {
    secret_token = data.aws_secretsmanager_secret_version.github_webhook_secret.secret_string
  }

  filter {
    json_path = "$.ref"
    match_equals = "refs/heads/hcw-76-initial-deployment-pipeline"
  }

  lifecycle {
    ignore_changes = [authentication_configuration]
  }
}
