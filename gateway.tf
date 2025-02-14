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

# Resource for the navi endpoint
resource "aws_api_gateway_resource" "phyllo_profile_analytics_navi" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_resource.phyllo_profile_analytics.id
  path_part   = "navi"
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

# Method for the navi endpoint
resource "aws_api_gateway_method" "post_phyllo_profile_analytics_navi" {
  rest_api_id      = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id      = aws_api_gateway_resource.phyllo_profile_analytics_navi.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.environment}-phyllo-profile-analytics"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.creator_catalyst_integrations.execution_arn}/*/*"

  depends_on = [aws_lambda_function.phyllo_profile_analytics]
}

# Permission for the navi endpoint
resource "aws_lambda_permission" "apigw_lambda_permission_navi" {
  statement_id  = "AllowAPIGatewayInvokeNavi"
  action        = "lambda:InvokeFunction"
  function_name = "${var.environment}-phyllo-profile-analytics-navigation"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.creator_catalyst_integrations.execution_arn}/*/POST/phyllo-profile-analytics/navi"

  depends_on = [aws_lambda_function.phyllo_profile_analytics_navigation]
}

resource "aws_api_gateway_deployment" "creator_catalyst_integrations_deployment" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  stage_name  = var.environment

  depends_on = [
    aws_api_gateway_method.post_phyllo_profile_analytics_initiate,
    aws_api_gateway_method.get_phyllo_profile_analytics_status,
    aws_api_gateway_method.post_phyllo_profile_analytics_navi
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
data "aws_region" "current" {}
resource "aws_api_gateway_integration" "post_phyllo_profile_analytics_initiate_integration" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.phyllo_profile_analytics_initiate.id
  http_method             = aws_api_gateway_method.post_phyllo_profile_analytics_initiate.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.phyllo_profile_analytics.arn}/invocations"

  depends_on = [aws_lambda_function.phyllo_profile_analytics]
}

resource "aws_api_gateway_integration" "get_phyllo_profile_analytics_status_integration" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.phyllo_profile_analytics_status.id
  http_method             = aws_api_gateway_method.get_phyllo_profile_analytics_status.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.phyllo_profile_analytics.arn}/invocations"
}


# Integration for the navi endpoint
resource "aws_api_gateway_integration" "post_phyllo_profile_analytics_navi_integration" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.phyllo_profile_analytics_navi.id
  http_method             = aws_api_gateway_method.post_phyllo_profile_analytics_navi.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.phyllo_profile_analytics_navigation.arn}/invocations"

  depends_on = [aws_lambda_function.phyllo_profile_analytics_navigation]
}

resource "aws_api_gateway_resource" "report_processing" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.root_resource_id
  path_part   = "reportprocessing"
}

resource "aws_api_gateway_resource" "unitary_wh" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.root_resource_id
  path_part   = "unitarywh"
}

resource "aws_api_gateway_method" "post_report_processing" {
  rest_api_id          = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id          = aws_api_gateway_resource.report_processing.id
  http_method          = "POST"
  authorization        = "NONE"
  api_key_required     = false
  request_validator_id = null
}

resource "aws_api_gateway_method" "post_unitary_wh" {
  rest_api_id          = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id          = aws_api_gateway_resource.unitary_wh.id
  http_method          = "POST"
  authorization        = "NONE"
  api_key_required     = false
  request_validator_id = null
}

resource "aws_lambda_permission" "apigw_lambda_permission_unitary_wh" {
  statement_id  = "AllowAPIGatewayInvokeUnitaryWH"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unitary_webhook.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.creator_catalyst_integrations.execution_arn}//POST/unitarywh"
}

resource "aws_api_gateway_method_settings" "post_unitary_wh_sdk_operation" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  stage_name  = var.environment
  method_path = "unitarywh/POST"

  settings {
    metrics_enabled = false
    logging_level   = "INFO"
  }

  depends_on = [aws_api_gateway_account.apigateway_account]
}

resource "aws_lambda_permission" "apigw_lambda_permission_report_processing" {
  statement_id  = "AllowAPIGatewayInvokeReportProcessing"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_creator_report.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.creator_catalyst_integrations.execution_arn}/POST/reportprocessing"
}

resource "aws_api_gateway_integration" "post_report_processing_integration" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.report_processing.id
  http_method             = aws_api_gateway_method.post_report_processing.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.process_creator_report.arn}/invocations"
}

resource "aws_api_gateway_integration" "post_unitary_wh_integration" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.unitary_wh.id
  http_method             = aws_api_gateway_method.post_unitary_wh.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.unitary_webhook.arn}/invocations"
}
resource "aws_iam_role" "apigateway_logging_role" {
  name = "APIGatewayCloudWatchLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "apigateway_logging_attachment" {
  name       = "APIGatewayLoggingAttachment"
  roles      = [aws_iam_role.apigateway_logging_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "apigateway_account" {
  cloudwatch_role_arn = aws_iam_role.apigateway_logging_role.arn
}

