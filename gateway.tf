resource "aws_api_gateway_rest_api" "creator_catalyst_integrations" {
  name        = "${var.environment}-creator-catalyst-integrations"
  description = "API Gateway for Creator Catalyst integrations"
  endpoint_configuration {
    types = ["EDGE"]
  }
  api_key_source               = "HEADER"
  disable_execute_api_endpoint = false
}

resource "aws_api_gateway_resource" "reportprocessing" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.root_resource_id
  path_part   = "reportprocessing"
}

resource "aws_api_gateway_method" "post_reportprocessing" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.reportprocessing.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_reportprocessing" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.reportprocessing.id
  http_method             = aws_api_gateway_method.post_reportprocessing.http_method
  type                    = "MOCK"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_resource" "unitarywh" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  parent_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.root_resource_id
  path_part   = "unitarywh"
}

resource "aws_api_gateway_method" "post_unitarywh" {
  rest_api_id   = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id   = aws_api_gateway_resource.unitarywh.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_unitarywh" {
  rest_api_id             = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  resource_id             = aws_api_gateway_resource.unitarywh.id
  http_method             = aws_api_gateway_method.post_unitarywh.http_method
  type                    = "MOCK"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_deployment" "creator_catalyst_integrations_deployment" {
  rest_api_id = aws_api_gateway_rest_api.creator_catalyst_integrations.id
  stage_name  = "dev"
}
