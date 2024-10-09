resource "aws_iam_role" "api_gateway_proxy_role" {
  name = "api-gateway-proxy-role-${var.env}"

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
  name = "api-gateway-proxy-policy-${var.env}"

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

resource "aws_api_gateway_rest_api" "app_api" {
  name = "hcw-api-${var.env}"
}

resource "aws_api_gateway_resource" "worker" {
  parent_id = aws_api_gateway_rest_api.app_api.root_resource_id
  path_part = "Worker"
  rest_api_id = aws_api_gateway_rest_api.app_api.id
}

resource "aws_api_gateway_method" "worker_get" {
  authorization = "NONE"
  http_method = "GET"
  resource_id = aws_api_gateway_resource.worker.id
  rest_api_id = aws_api_gateway_rest_api.app_api.id
}

resource "aws_api_gateway_integration" "worker_get_lambda_integration" {
  http_method = aws_api_gateway_method.worker_get.http_method
  resource_id = aws_api_gateway_resource.worker.id
  rest_api_id = aws_api_gateway_rest_api.app_api.id

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_alias.live.invoke_arn
}

resource "aws_api_gateway_deployment" "live" {
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.worker,
      aws_api_gateway_method.worker_get,
      aws_api_gateway_integration.worker_get_lambda_integration
    ]))
  }
  rest_api_id = aws_api_gateway_rest_api.app_api.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "live" {
  deployment_id = aws_api_gateway_deployment.live.id
  rest_api_id = aws_api_gateway_rest_api.app_api.id
  stage_name = "live"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id        = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hcw-app.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.app_api.execution_arn}/*/*/*"
  qualifier = aws_lambda_alias.live.name
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name = "gateway-logs-${var.env}"
}
