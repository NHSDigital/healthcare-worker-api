resource "aws_iam_role" "api_gateway_proxy_role" {
  name = "api-gateway-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "api_gateway_proxy_policy" {
  name = "api-gateway-proxy-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [
        aws_lambda_function.hcw-app.arn,
        "${aws_lambda_function.hcw-app.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_proxy_policy_attach" {
  role       = aws_iam_role.api_gateway_proxy_role.name
  policy_arn = aws_iam_policy.api_gateway_proxy_policy.arn
}

resource "aws_apigatewayv2_api" "app_api" {
  name          = "hcw-api-${var.env}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_route" "worker_endpoint" {
  api_id    = aws_apigatewayv2_api.app_api.id
  route_key = "GET /Worker"

  target = "integrations/${aws_apigatewayv2_integration.api_lambda_integration.id}"
}

resource "aws_apigatewayv2_integration" "api_lambda_integration" {
  api_id           = aws_apigatewayv2_api.app_api.id
  integration_type = "AWS_PROXY"
  connection_type  = "INTERNET"
  # TODO: Should this be internet or VPC_LINK?

  integration_method     = "POST"
  integration_uri        = aws_lambda_alias.live.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_vpc_link" "api_vpc_link" {
  name = "api-vpc-link-${var.env}"

  security_group_ids = [aws_security_group.app_security_group.id]
  subnet_ids         = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id, aws_subnet.subnet_c.id]
}

resource "aws_apigatewayv2_stage" "api_gw_live_stage" {
  api_id = aws_apigatewayv2_api.app_api.id
  name   = "live"

  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      httpMethod     = "$content.httpMethod"
      ip             = "$context.identity.sourceIp"
      protocol       = "$context.protocol"
      requestId      = "$context.requestId"
      requestTime    = "$context.requestTime"
      responseLength = "$context.responseLength"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
    })
  }
}

resource "aws_apigatewayv2_deployment" "api_deployment" {
  api_id = aws_apigatewayv2_api.app_api.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name = "gateway-logs-${var.env}"

}
