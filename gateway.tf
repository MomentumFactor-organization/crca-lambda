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
resource "aws_api_gateway_method" "post_phyllo_profile_analytics_initiate" {
  rest_api_id      = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id      = aws_api_gateway_resource.phyllo_profile_analytics_initiate.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}
resource "aws_api_gateway_method" "get_phyllo_profile_analytics_status" {
  rest_api_id      = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id      = aws_api_gateway_resource.phyllo_profile_analytics_status.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}
resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.environment}-phyllo-profile-analytics"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.creator_catalyst_integrations.execution_arn}/*/*"
}
resource "aws_api_gateway_deployment" "creator_catalyst_integrations_deployment" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  stage_name  = var.environment

  depends_on = [
    aws_api_gateway_method.post_phyllo_profile_analytics_initiate,
    aws_api_gateway_method.get_phyllo_profile_analytics_status
  ]
}
resource "aws_api_gateway_stage" "develop_stage" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  stage_name  = var.environment

  deployment_id = aws_api_gateway_deployment.creator_catalyst_integrations_deployment.id

  description = "Development stage for Creator Catalyst integrations"
}
resource "aws_api_gateway_usage_plan" "api_gateway_usage_plan" {
  name = "${var.environment}-api-gateway-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
    stage  = aws_api_gateway_stage.develop_stage.stage_name
  }

  quota_settings {
    limit  = 20
    offset = 2
    period = "WEEK"
  }

  throttle_settings {
    burst_limit = 5
    rate_limit  = 10
  }
}
resource "aws_api_gateway_api_key" "api_key" {
  name    = "${var.environment}-api-key"
  enabled = true
}
resource "aws_api_gateway_usage_plan_key" "api_usage_plan_key" {
  usage_plan_id = aws_api_gateway_usage_plan.api_gateway_usage_plan.id
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
}
data "aws_lambda_function" "phyllo_profile_analytics" {
  function_name = "${var.environment}-phyllo-profile-analytics"
}
data "aws_region" "current" {}
resource "aws_api_gateway_integration" "post_phyllo_profile_analytics_initiate_integration" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.phyllo_profile_analytics_initiate.id
  http_method             = aws_api_gateway_method.post_phyllo_profile_analytics_initiate.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${data.aws_lambda_function.phyllo_profile_analytics.arn}/invocations"
}

resource "aws_api_gateway_integration" "get_phyllo_profile_analytics_status_integration" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.phyllo_profile_analytics_status.id
  http_method             = aws_api_gateway_method.get_phyllo_profile_analytics_status.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${data.aws_lambda_function.phyllo_profile_analytics.arn}/invocations"
}

