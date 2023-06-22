resource "aws_api_gateway_rest_api" "api" {
  name        = "api"
  description = "API Gateway"
}
-- this is the policy for the API Gateway, this policy is used to allow access to the API Gateway from only specific IP addresses, which means that only these servers can access the API Gateway
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
              "12.11.117.12/32",
              "44.245.128.80/32",
              "199.188.255.126/32"
            ]
          }
        }
      },
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.edify-api.id}/*/*/*"
      }
    ]
  })
}
