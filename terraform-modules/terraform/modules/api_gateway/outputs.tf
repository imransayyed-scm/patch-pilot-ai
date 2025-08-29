# modules/api_gateway/outputs.tf
output "api_endpoint" {
  description = "The invocation URL for the API Gateway stage."
  value       = aws_api_gateway_stage.this.invoke_url
}