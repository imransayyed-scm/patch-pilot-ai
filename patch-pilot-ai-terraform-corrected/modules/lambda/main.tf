resource "aws_lambda_function" "this" {
  function_name = var.function_name
  s3_bucket     = var.s3_bucket_for_code != "" ? var.s3_bucket_for_code : null
  s3_key        = var.s3_key_for_code != "" ? var.s3_key_for_code : null
  filename      = var.local_zip != "" ? var.local_zip : null
  handler       = var.handler
  runtime       = var.runtime
  role          = var.role_arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  environment { variables = var.environment }

  tags = var.tags
}
output "lambda_arn" { value = aws_lambda_function.this.arn }
output "lambda_name" { value = aws_lambda_function.this.function_name }
