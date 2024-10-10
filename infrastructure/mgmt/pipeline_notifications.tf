resource "aws_sns_topic" "pipeline_updates" {
  name = "pipeline-updates"
}

data "aws_iam_policy_document" "update_access" {
  statement {
    actions = ["sns:Publish"]

    principals {
      type = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }

    resources = [aws_sns_topic.pipeline_updates.arn]
  }
}

resource "aws_sns_topic_policy" "pipeline_updates" {
  arn = aws_sns_topic.pipeline_updates.arn
  policy = data.aws_iam_policy_document.update_access.json
}

resource "aws_codestarnotifications_notification_rule" "pipeline_update_notifications" {
  name = "pipeline-update-notification-rule"
  resource = aws_codepipeline.app_deployment_pipeline.arn

  detail_type = "BASIC"
  event_type_ids = ["codepipeline-pipeline-stage-execution-started", "codepipeline-pipeline-stage-execution-succeeded", "codepipeline-pipeline-stage-execution-failed"]

  target {
    address = aws_sns_topic.pipeline_updates.arn
  }
}

resource "aws_iam_role" "pipeline_update_lambda_role" {
  name = "PipelineUpdateLambdaRole"
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

data "archive_file" "lambda_source" {
  type = "zip"
  source_file = "${path.module}/status_reporting/status_reporting.py"
  output_path = "${path.module}/status_reporting.zip"
}

resource "aws_lambda_function" "pipeline_update_lambda" {
  filename = "${path.module}/status_reporting.zip"
  function_name = "pipeline-update-handler"
  role = aws_iam_role.pipeline_update_lambda_role.arn
  handler = "status_reporting.handler"

  source_code_hash = data.archive_file.lambda_source.output_sha512

  runtime = "python3.12"
}

resource "aws_iam_policy" "pipeline_update_lambda" {
  name = "pipeline-update-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
    }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pipeline_update_policy_attachment" {
  role = aws_iam_role.pipeline_update_lambda_role.name
  policy_arn = aws_iam_policy.pipeline_update_lambda.arn
}

resource "aws_sns_topic_subscription" "pipeline_update_subscription" {
  topic_arn = aws_sns_topic.pipeline_updates.arn
  protocol = "lambda"
  endpoint = aws_lambda_function.pipeline_update_lambda.arn
}
