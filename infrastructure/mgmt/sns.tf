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
