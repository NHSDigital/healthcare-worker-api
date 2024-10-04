resource "aws_secretsmanager_secret" "github_webhook_secret" {
  name = "github_webhook_secret"
}

data "aws_secretsmanager_secret" "github_webhook_secret" {
  arn = aws_secretsmanager_secret.github_webhook_secret.arn
}

data "aws_secretsmanager_secret_version" "github_webhook_secret" {
  secret_id = data.aws_secretsmanager_secret.github_webhook_secret.id
}
