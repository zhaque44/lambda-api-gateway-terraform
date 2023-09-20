resource "aws_iam_role" "lambda_one_exec" {
  name = "lambda-one"

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

resource "aws_iam_role_policy_attachment" "lambda_one_policy" {
  role       = aws_iam_role.lambda_one_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda-one" {
  function_name = "lambda-one"
  role          = aws_iam_role.lambda_one_exec.arn
  image_uri     = "<account-id>.dkr.ecr.<region>.amazonaws.com/lambda-one:latest"
  package_type  = "Image"
  timeout       = 60
  memory_size   = 512
  publish       = true

  environment {
    variables = {
      "MQ_HOST"                     = "MQ_HOST",
      "AUTH_TOKEN"                  = "AUTH_TOKEN",
      "MQ_USERNAME"                 = "MQ_USERNAME",
      "MQ_PASSWORD"                 = "MQ_PASSWORD",
      "LAMBDA_NET_SERIALIZER_DEBUG" = true
    }
  }

  image_config {
    working_directory = "/var/task"
    command = ["index.lambda-one"]
  }

  depends_on = [
    aws_mq_broker.mq-broker,
  ]
}

resource "aws_cloudwatch_log_group" "lambda-one" {
  name              = "/aws/lambda/lambda-one"
  retention_in_days = 10
}

