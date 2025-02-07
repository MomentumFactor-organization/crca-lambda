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
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.phyllo_profile_analytics_initiate.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "get_phyllo_profile_analytics_status" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.phyllo_profile_analytics_status.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "post_phyllo_profile_analytics_initiate" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.phyllo_profile_analytics_initiate.id
  http_method             = aws_api_gateway_method.post_phyllo_profile_analytics_initiate.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:lambda:us-west-1:396913719177:function:develop-phyllo-profile-analytics"
}

resource "aws_api_gateway_integration" "get_phyllo_profile_analytics_status" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.phyllo_profile_analytics_status.id
  http_method             = aws_api_gateway_method.get_phyllo_profile_analytics_status.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:lambda:us-west-1:396913719177:function:develop-phyllo-profile-analytics"
}

resource "aws_api_gateway_deployment" "creator_catalyst_integrations_deployment" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  stage_name  = "dev"

  depends_on = [
    aws_api_gateway_method.post_phyllo_profile_analytics_initiate,
    aws_api_gateway_method.get_phyllo_profile_analytics_status
  ]
}

resource "aws_api_gateway_api_key" "develop_integration_apigw" {
  name        = "develop-integration-apigw"
  description = "API Key for Phyllo Profile Analytics"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "develop_api_gateway_usage_plan" {
  name        = "develop-api-gateway-usage-plan"
  description = "Usage plan for Phyllo Profile Analytics API Gateway"

  api_stages {
    api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
    stage  = aws_api_gateway_deployment.creator_catalyst_integrations_deployment.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "develop_api_gateway_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.develop_integration_apigw.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.develop_api_gateway_usage_plan.id
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "develop-phyllo-profile-analytics"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.creator_catalyst_integrations.execution_arn}/*/*"
}
