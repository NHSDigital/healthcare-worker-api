
resource "aws_codebuild_project" "hcw-deployment-static-env-trigger" {
  name         = "hcw-deployment-static-env-trigger"
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
    buildspec = "buildspecs/static-env-deploy-trigger.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }
}

resource "aws_codepipeline" "static_env_deployment_pipeline" {
  name           = "hcw-api-static-env-deployment"
  role_arn       = aws_iam_role.app_deployment_pipeline_role.arn
  pipeline_type  = "V2"
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

      namespace = "Source"
    }
  }

  stage {
    name = "Int-Approval"
    action {
      category = "Approval"
      name     = "Int-Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Int-Deploy"

    action {
      name     = "Deploy"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts = ["source_output"]

      role_arn = "arn:aws:iam::711387117641:role/CodeBuildDeployJobRole"

      configuration = {
        ProjectName = "hcw-api-deploy"

        EnvironmentVariables = jsonencode([
          {
            name  = "environment_name"
            value = "int"
            type  = "PLAINTEXT"
          },
          {
            name  = "account_name"
            value = "dev"
            type  = "PLAINTEXT"
          },
          {
            name  = "app_s3_filename"
            value = "#{variables.commit_id}.zip"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Ref-Approval"
    action {
      category = "Approval"
      name     = "Ref-Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Ref-Deploy"

    action {
      name     = "Deploy"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts = ["source_output"]

      role_arn = "arn:aws:iam::711387117641:role/CodeBuildDeployJobRole"

      configuration = {
        ProjectName = "hcw-api-deploy"

        EnvironmentVariables = jsonencode([
          {
            name  = "environment_name"
            value = "ref"
            type  = "PLAINTEXT"
          },
          {
            name  = "account_name"
            value = "dev"
            type  = "PLAINTEXT"
          },
          {
            name  = "app_s3_filename"
            value = "#{variables.commit_id}.zip"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  variable {
    name = "commit_id"
  }
}
