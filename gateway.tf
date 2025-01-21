resource "aws_api_gateway_rest_api" "creator_catalyst_integrations" {
  name        = "${var.environment}-creator-catalyst-integrations"
  description = "API Gateway for Creator Catalyst integrations"
  endpoint_configuration {
    types = ["EDGE"]
  }
  api_key_source               = "HEADER"
  disable_execute_api_endpoint = false
}

resource "aws_api_gateway_resource" "phyllo_profile_analytics" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.root_resource_id
  path_part   = "phyllo-profile-analytics"
}

resource "aws_api_gateway_resource" "status" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_resource.phyllo_profile_analytics.id
  path_part   = "status"
}

resource "aws_api_gateway_resource" "initiate" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_resource.phyllo_profile_analytics.id
  path_part   = "initiate"
}

resource "aws_api_gateway_method" "status_options" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.status.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "status_post" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.status.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "initiate_options" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.initiate.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "initiate_post" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.initiate.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "status_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.status.id
  http_method             = aws_api_gateway_method.status_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.process_creator_report.invoke_arn
}

resource "aws_api_gateway_integration" "initiate_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.initiate.id
  http_method             = aws_api_gateway_method.initiate_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.process_creator_report.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_creator_report.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.creator_catalyst_integrations.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  stage_name  = var.environment

  depends_on = [
    aws_api_gateway_integration.status_post_integration,
    aws_api_gateway_integration.initiate_post_integration
  ]
}
