output "api_base_url" {
  description = "API Gateway base URL"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}

output "dynamodb_table" {
  description = "Findings DynamoDB table name"
  value       = aws_dynamodb_table.findings.name
}
