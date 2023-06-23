resource "aws_iam_role" "lambda_three_exec" {
  name = "lambda-three"

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

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.lambda_three_exec.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "secrets_policy" {
  role       = aws_iam_role.lambda_three_exec.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "mq_policy" {
  role       = aws_iam_role.lambda_three_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonMQFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_three_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda-three" {
  function_name = "lambda-three"
  role          = aws_iam_role.lambda_three_exec.arn
  image_uri     = "<account-id>.dkr.ecr.<region>.amazonaws.com/lambda-three:latest"
  package_type  = "Image"
  timeout       = 60
  memory_size   = 3000
  publish       = true

  environment {
    variables = {
      "MQ_USERNAME" = "MQ_USERNAME",
      "MQ_PASSWORD" = "MQ_PASSWORD"
    }
  }

  image_config {
    working_directory = "/var/task"
    command = ["index.lambda-three"]
  }
}

resource "aws_cloudwatch_log_group" "lambda-three" {
  name              = "/aws/lambda/lambda-three"
  retention_in_days = 10

  lifecycle {
    prevent_destroy = false
  }
}

# create trigger for mq broker
resource "aws_lambda_event_source_mapping" "lambda-three" {
  event_source_arn = aws_mq_broker.mq-broker.arn
  function_name    = aws_lambda_function.lambda_three_exec.arn
  enabled          = true
  batch_size       = 1

  source_access_configuration {
    type = "BASIC_AUTH"
    uri  = aws_secretsmanager_secret.mq-access.arn
  }

  source_access_configuration {
    type = "VIRTUAL_HOST"
    uri  = "/"
  }
  queues = ["queue-name"]

  depends_on = [
    aws_mq_broker.mq-broker,
  ]
}
