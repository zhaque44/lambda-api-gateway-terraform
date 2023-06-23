resource "aws_iam_role" "lambda_two_exec" {
  name = "lambda-two"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.lambda_two_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_two_policy" {
  role       = aws_iam_role.lambda_two_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_vpc" "existing_vpc" {
  id = "vpc-01bd705fj9e25dc8d"
}

data "aws_subnet" "subnet_1" {
  id = "subnet-0362603a38426e7b0"
}

data "aws_subnet" "subnet_2" {
  id = "subnet-0da479680ed6ed4b9"
}

resource "aws_lambda_function" "lambda-two" {
  function_name = "lambda-two"
  role          = aws_iam_role.lambda_two_exec.arn
  image_uri     = "<account-id>.dkr.ecr.<region>.amazonaws.com/lambda-two:latest"
  package_type  = "Image"
  timeout       = 60
  memory_size   = 512
  publish       = true

  environment {
    variables = {
      "API_URL"                   = "API_URL",
      "API_TOKEN"                 = "API_TOKEN",
    }
  }

  vpc_config {
    subnet_ids = [
      data.aws_subnet.subnet_1.id,
      data.aws_subnet.subnet_2.id
    ]
    security_group_ids = ["sg-08a220536725ad86b", "sg-0808ec9a6a8057662", "sg-08087e084fe111728", "sg-0668a33a2a97466a6"]
  }
}

resource "aws_cloudwatch_log_group" "lambda-two" {
  name              = "/aws/lambda/lambda-two"
  retention_in_days = 10

  lifecycle {
    prevent_destroy = false
  }
}
