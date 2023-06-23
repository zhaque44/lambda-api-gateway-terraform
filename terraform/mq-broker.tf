resource "aws_mq_broker" "mq-broker" {
  broker_name                = "mq-broker"
  engine_type                = "RabbitMQ"
  engine_version             = "3.10.10"
  host_instance_type         = "mq.t3.micro"
  apply_immediately          = true
  auto_minor_version_upgrade = true
  deployment_mode            = "SINGLE_INSTANCE"
  publicly_accessible        = true

  user {
    username = "MQUser"
    password = "m3tdc8VtKMIJ"
  }

  logs {
    general = true
  }
}


resource "aws_iam_role_policy" "mq-broker" {
  name = "mq-broker-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mq:DescribeBroker"
        ]
        Resource = aws_mq_broker.mq-broker.arn
      }
    ]
  })

  role = aws_iam_role.lambda_one_exec.id
}

resource "aws_secretsmanager_secret" "mq-access" {
  name = "MQAccess"
  
  description = "RabbitMQ access for MQUser"
  recovery_window_in_days = 0

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "mq-access" {
  secret_id = aws_secretsmanager_secret.mq-access.id
  secret_string = jsonencode({
    "username" = "username"
    "password" = "s3cr3t"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }

  depends_on = [
    aws_secretsmanager_secret.mq-access
  ]
}
