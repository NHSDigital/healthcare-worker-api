resource "aws_iam_role" "build_agent_role" {
  name = "build_agent_role"

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

  tags = {
    env = "mgmt"
  }
}

resource "aws_iam_role_policy" "build_agent_policy" {
  name = "build_agent_policy"
  role = aws_iam_role.build_agent_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": "s3:PutObject",
        "Resource": "*"
      }
    ]
  })
}

