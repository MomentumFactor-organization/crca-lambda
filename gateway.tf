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

resource "aws_api_gateway_resource" "phyllo_profile_analytics_initiate" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_resource.phyllo_profile_analytics.id
  path_part   = "initiate"
}

resource "aws_api_gateway_resource" "phyllo_profile_analytics_status" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_resource.phyllo_profile_analytics.id
  path_part   = "status"
}

resource "aws_api_gateway_method" "options_phyllo_profile_analytics" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.phyllo_profile_analytics.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_phyllo_profile_analytics_initiate" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.phyllo_profile_analytics_initiate.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_phyllo_profile_analytics_status" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.phyllo_profile_analytics_status.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "post_phyllo_profile_analytics_initiate" {
  rest_api_id      = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id      = aws_api_gateway_resource.phyllo_profile_analytics_initiate.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

data "aws_lambda_function" "phyllo_profile_analytics" {
  function_name = "${var.environment}-phyllo-profile-analytics"
}

resource "aws_api_gateway_integration" "post_phyllo_profile_analytics_initiate" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.phyllo_profile_analytics_initiate.id
  http_method             = aws_api_gateway_method.post_phyllo_profile_analytics_initiate.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${data.aws_lambda_function.phyllo_profile_analytics.invoke_arn}/invocations"
}

resource "aws_api_gateway_integration" "options_phyllo_profile_analytics" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id = aws_api_gateway_resource.phyllo_profile_analytics.id
  http_method = "OPTIONS"
  type        = "MOCK"

  depends_on = [aws_api_gateway_method.options_phyllo_profile_analytics]
}

resource "aws_api_gateway_integration" "options_phyllo_profile_analytics_initiate" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id = aws_api_gateway_resource.phyllo_profile_analytics_initiate.id
  http_method = "OPTIONS"
  type        = "MOCK"

  depends_on = [aws_api_gateway_method.options_phyllo_profile_analytics]
}

resource "aws_api_gateway_integration" "options_phyllo_profile_analytics_status" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id = aws_api_gateway_resource.phyllo_profile_analytics_status.id
  http_method = "OPTIONS"
  type        = "MOCK"

  depends_on = [aws_api_gateway_method.options_phyllo_profile_analytics_status]
}

resource "aws_api_gateway_deployment" "creator_catalyst_integrations_deployment" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  stage_name  = var.environment

  depends_on = [
    aws_api_gateway_integration.post_phyllo_profile_analytics_initiate,
    aws_api_gateway_integration.options_phyllo_profile_analytics,
    aws_api_gateway_integration.options_phyllo_profile_analytics_initiate,
    aws_api_gateway_integration.options_phyllo_profile_analytics_status
  ]
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.environment}-phyllo-profile-analytics"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.creator_catalyst_integrations.execution_arn}/*/*"
}
