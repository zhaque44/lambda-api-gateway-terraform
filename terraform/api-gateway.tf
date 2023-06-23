resource "aws_api_gateway_rest_api" "api" {
  name        = "api"
  description = "API Gateway"
}
-- # this is the IP address of the Edify servers, which means that only theese IPs can access the API Gateway
resource "aws_api_gateway_rest_api_policy" "example" { 
  rest_api_id = aws_api_gateway_rest_api.api.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Deny",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/*",
        "Condition": {
          "NotIpAddress": { 
            "aws:SourceIp": [
              "52.11.108.82/32",
              "44.280.128.40/32",
              "199.188.244.128/32"
            ]
          }
        }
      },
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/*"
      }
    ]
  })
}

resource "aws_api_gateway_resource" "v1" { 
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "v1"
}

resource "aws_api_gateway_resource" "payment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "payment"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.payment.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_integration" "proxy" { 
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = "ANY"
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.lambda-one.invoke_arn
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.proxy.id
  http_method      = "ANY" 
  authorization    = "NONE"
  api_key_required = false
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_resource" "customer" { 
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "customer"
}
-- This is the second proxy resource, that is used for the customer endpoint, # this is the resource for the customer endpoint
resource "aws_api_gateway_resource" "proxy2" { 
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.customer.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_integration" "proxy2" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.proxy2.id
  http_method             = "ANY"
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.lambda-two.invoke_arn
}

resource "aws_api_gateway_method" "proxy2" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.proxy2.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = false
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_lambda_permission" "lambda-one" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-one.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "lambda-two" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-two.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "api" {
  name = "/aws/api-gateway/api"
  retention_in_days = 30

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_api_gateway_stage" "gateway_api_stage" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"
  variables = {
    "lambdaARN" = aws_lambda_function.lambda-one.invoke_arn,
    "lambdaARN2" = aws_lambda_function.lambda-two.invoke_arn
  }
  deployment_id = aws_api_gateway_deployment.gateway_api_deployment.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_deployment.gateway_api_deployment]
}

resource "aws_api_gateway_deployment" "gateway_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "development"
  variables = {
    "lambdaARN" = aws_lambda_function.lambda-one.invoke_arn,
    "lambdaARN2" = aws_lambda_function.lambda-two.invoke_arn
  }
  depends_on = [aws_api_gateway_integration.proxy, aws_api_gateway_integration.proxy2]
}
