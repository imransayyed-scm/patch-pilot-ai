resource "aws_lambda_function" "function" {
  function_name = var.function_name
  filename      = ""
  s3_bucket     = var.s3_bucket_for_code != "" ? var.s3_bucket_for_code : null
  s3_key        = var.s3_key_for_code != "" ? var.s3_key_for_code : null
  handler       = var.handler
  runtime       = var.runtime
  role          = var.role_arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  environment {
    variables = var.environment
  }

  tags = var.tags
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = var.event_rule_arn
  depends_on = [aws_lambda_function.function]
}
