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
  execution_mode = "PARALLEL"

  artifact_store {
    location = aws_s3_bucket.build_artifacts.bucket
    type     = "S3"
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

# TODO: Figure out how to get a webhook directly into codepipeline working, for now using an intermediate codebuild job
resource "aws_iam_role" "deployment_trigger_role" {
  name = "DeploymentTriggerRole"

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

resource "aws_iam_policy" "deployment_trigger_policy" {
  name = "deployment_trigger_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": "codepipeline:StartPipelineExecution",
        "Resource": aws_codepipeline.app_deployment_pipeline.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "deployment_triggerattach_policy" {
  role       = aws_iam_role.deployment_trigger_role.name
  policy_arn = aws_iam_policy.deployment_trigger_policy.arn
}

resource "aws_codebuild_project" "hcw-deployment-trigger" {
  name         = "hcw-deployment-trigger"
  service_role = aws_iam_role.deployment_trigger_role.arn

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
    buildspec = "buildspecs/trigger_deployment.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }
}


