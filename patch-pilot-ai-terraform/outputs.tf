output "lambda_function_arn" {
  value = module.patch_lambda.lambda_arn
}

output "s3_bucket" {
  value = module.reports_bucket.bucket_id
}

output "dynamodb_table" {
  value = module.recipients_table.table_name
}
