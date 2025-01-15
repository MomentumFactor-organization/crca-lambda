# Terraform script

The following document its to provide more information on how to deploy a lambda function that has been create and tested locally, and now its ready to be deployed to AWS as resources.

The following steps its going to detailed the changes that needs to be made in order to update the plans from Terraform.

Before we start, we assume that you have already cloned this repository on your local machine.

## Create a lambda function with Terraform script

You can open and add to the end of the section corresponding to Lambdas in the main.tf file.

```hcl
resource "aws_lambda_function" "<resource_name>" {
  filename      = "compressed/${var.environment}-<function-name>.zip"
  function_name = "${var.environment}-<function-name>"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  environment {
    # List of the environment variables
    variables = {
      S3_BUCKET       = aws_s3_bucket.creator_catalyst_analytics.bucket
    }
  }

  # You can add the existent layers or add a new ones.
  layers = [
    aws_lambda_layer_version.requests_layer[0].arn
  ]
}
```

## Add a SQS trigger

As an example, we are adding into the Terraform script above the function a SQS resource to use it as a trigger of the function.

```hcl
resource "aws_sqs_queue" "<sqs_resource>" {
  name = "${var.environment}-sqs-name"
}
```

## Link lambda function with SQS trigger

Once its added, we need to linked to the functions, below the function we add a block as the example.

```hcl
resource "aws_lambda_event_source_mapping" "function_name_trigger" {
  event_source_arn = aws_sqs_queue.<resource_name>.arn
  function_name    = aws_lambda_function.<function_name>.function_name
  batch_size       = 1
  enabled          = true
}
```

## Deploy the update to AWS

Regarding the environment in which you are working on the default environment its **develop** so we are assuming that you are working on a feature branch that has been committed into **develop branch**.

For your convenience, all terraform commands have been developed within the Makefile, so to deploy you will only have to run it.

```bash
make
```

Except if your deployment is not on that branch, for which you will have to create a specific PR.
