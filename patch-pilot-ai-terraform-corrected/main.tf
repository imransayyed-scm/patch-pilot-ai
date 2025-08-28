terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

module "frontend" {
  source = "./modules/s3_cloudfront"
  site_bucket_name = var.frontend_bucket_name
  cloudfront_alias = var.frontend_alias
  tags = var.tags
}

module "db" {
  source = "./modules/dynamodb"
  table_name = var.dynamodb_table_name
  tags = var.tags
}

module "lambda_iam" {
  source = "./modules/iam"
  role_name = var.lambda_role_name
  tags = var.tags
  attach_inspector_ssm = true
}

module "backend_lambda" {
  source = "./modules/lambda"
  function_name = var.backend_lambda_name
  handler = var.backend_handler
  runtime = var.lambda_runtime
  role_arn = module.lambda_iam.role_arn
  s3_bucket_for_code = var.lambda_code_s3_bucket
  s3_key_for_code = var.backend_lambda_s3_key
  environment = merge(var.lambda_environment, { G_GEMINI_API_KEY = var.gemini_api_key })
  tags = var.tags
}

module "sync_lambda" {
  source = "./modules/lambda"
  function_name = var.sync_lambda_name
  handler = var.sync_handler
  runtime = var.lambda_runtime
  role_arn = module.lambda_iam.role_arn
  s3_bucket_for_code = var.lambda_code_s3_bucket
  s3_key_for_code = var.sync_lambda_s3_key
  environment = var.lambda_environment
  tags = var.tags
}

module "api" {
  source = "./modules/api_gateway"
  name = var.api_name
  lambda_arn = module.backend_lambda.lambda_arn
  tags = var.tags
}

module "schedule" {
  source = "./modules/eventbridge"
  name = var.schedule_name
  schedule_expression = var.schedule_expression
  target_arn = module.sync_lambda.lambda_arn
  input = jsonencode({ action = "sync_inspector_findings" })
  tags = var.tags
}

output "api_endpoint" {
  value = module.api.api_endpoint
}
