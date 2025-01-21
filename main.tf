terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

variable "environment" {
  description = "The environment for the deployment (e.g. develop, staging, production)"
  type        = string
}

# Data
data "aws_iam_role" "glue_role" {
  name = "AWSGlueServiceRole"
}

data "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-role"
}

# Outputs to use the ARNs of the layers in functions
output "boto3_layer_arn" {
  value = aws_lambda_layer_version.boto3_layer.arn
}

output "requests_layer_arn" {
  value = aws_lambda_layer_version.requests_layer.arn
}

output "psycopg2_layer_arn" {
  value = aws_lambda_layer_version.psycopg2_layer.arn
}
