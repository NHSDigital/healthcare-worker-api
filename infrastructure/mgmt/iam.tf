resource "aws_iam_role" "build_agent_role" {
  name = "GitHubBuildAgentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_openid_provider.id
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub": "repo:NHSDigital/healthcare-worker-api"
          }
        }
      },
    ]
  })

  max_session_duration = 3600 # One hour (minimum possible)
}

resource "aws_iam_policy" "github_build_agent_policy" {
  name = "github_build_agent_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "s3:PutObject",
        "Resource" : "*"
      }
    ]
  })
}

data "tls_certificate" "github_openid" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_openid_provider" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_openid.certificates[0].sha1_fingerprint]
}
