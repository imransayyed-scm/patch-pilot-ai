output "frontend_bucket" { value = module.frontend.site_bucket_id }
output "dynamodb_table" { value = module.db.table_name }
output "backend_lambda_arn" { value = module.backend_lambda.lambda_arn }
output "sync_lambda_arn" { value = module.sync_lambda.lambda_arn }
output "api_endpoint" { value = module.api.api_endpoint }
