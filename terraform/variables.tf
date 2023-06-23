variable "lambda_one_image_uri" {
  type = string
}

variable "lambda_two_image_uri" {
  type = string
}

variable "lambda_three_image_uri" {
  type = string
}

variable "environment" {
  type = string
  default = "dev"
}

variable "region" {
  description = "The region where the resources will be created (e.g. us-east-1)"
}

variable "account_id" {
  description = "The AWS account ID where the resources will be created"
}
