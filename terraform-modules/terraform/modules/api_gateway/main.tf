# modules/api_gateway/main.tf
resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "API for ${var.api_name}"
  tags        = var.tags
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([ for r in values(aws_api_gateway_resource.this) : r.id ] ++ [ for m in values(aws_api_gateway_method.this) : m.id ] ++ [ for i in values(aws_api_gateway_integration.this) : i.id ]))
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "Prod"
  tags          = var.tags
}

# Create resources for each unique path part
locals {
  path_parts = distinct([ for path in keys(var.lambda_integrations) : split("/", path) if length(split("/", path)) > 1 ])
}

resource "aws_api_gateway_resource" "this" {
  for_each    = toset(local.path_parts)
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.key
}

# Create methods and integrations
resource "aws_api_gateway_method" "this" {
  for_each      = var.lambda_integrations
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = length(split("/", each.key)) > 1 ? aws_api_gateway_resource.this[split("/", each.key)].id : aws_api_gateway_rest_api.this.root_resource_id
  http_method   = each.value.http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "this" {
  for_each                = var.lambda_integrations
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = length(split("/", each.key)) > 1 ? aws_api_gateway_resource.this[split("/", each.key)].id : aws_api_gateway_rest_api.this.root_resource_id
  http_method             = aws_api_gateway_method.this[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.lambda_invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  for_each      = var.lambda_integrations
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_invoke_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/${each.value.http_method}${each.key}"
}

# --- CORS Preflight OPTIONS Methods ---
resource "aws_api_gateway_method" "cors_options" {
  for_each      = { for k, v in var.lambda_integrations : k => v if v.http_method != "OPTIONS" }
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = length(split("/", each.key)) > 1 ? aws_api_gateway_resource.this[split("/", each.key)].id : aws_api_gateway_rest_api.this.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_options" {
  for_each              = { for k, v in var.lambda_integrations : k => v if v.http_method != "OPTIONS" }
  rest_api_id           = aws_api_gateway_rest_api.this.id
  resource_id           = length(split("/", each.key)) > 1 ? aws_api_gateway_resource.this[split("/", each.key)].id : aws_api_gateway_rest_api.this.root_resource_id
  http_method           = aws_api_gateway_method.cors_options[each.key].http_method
  type                  = "MOCK"
  request_templates = { "application/json" = "{\"statusCode\": 200}" }
}

resource "aws_api_gateway_method_response" "cors_options" {
  for_each    = { for k, v in var.lambda_integrations : k => v if v.http_method != "OPTIONS" }
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = length(split("/", each.key)) > 1 ? aws_api_gateway_resource.this[split("/", each.key)].id : aws_api_gateway_rest_api.this.root_resource_id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "cors_options" {
  for_each    = { for k, v in var.lambda_integrations : k => v if v.http_method != "OPTIONS" }
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = length(split("/", each.key)) > 1 ? aws_api_gateway_resource.this[split("/", each.key)].id : aws_api_gateway_rest_api.this.root_resource_id
  http_method = aws_api_gateway_method.cors_options[each.key].http_method
  status_code = aws_api_gateway_method_response.cors_options[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
``````terraform