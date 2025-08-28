terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

module "reports_bucket" {
  source = "./modules/s3"
  bucket_name = var.reports_bucket_name
  tags = var.tags
}

module "recipients_table" {
  source = "./modules/dynamodb"
  table_name = var.recipients_table_name
  read_capacity  = 5
  write_capacity = 5
  tags = var.tags
}

module "lambda_iam" {
  source = "./modules/iam"
  role_name = var.lambda_role_name
  tags = var.tags
  # Additional inline policy can be passed in var.lambda_inline_policy (JSON)
}

module "patch_lambda" {
  source = "./modules/lambda"
  function_name = var.lambda_function_name
  handler = var.lambda_handler
  runtime = var.lambda_runtime
  role_arn = module.lambda_iam.role_arn
  s3_bucket_for_code = var.lambda_code_s3_bucket
  s3_key_for_code = var.lambda_code_s3_key
  environment = var.lambda_environment
  tags = var.tags
}

module "ses_sender" {
  source = "./modules/ses"
  email_identity = var.ses_sender_email
  region = var.aws_region
  tags = var.tags
}

module "schedule" {
  source = "./modules/eventbridge"
  name = var.event_rule_name
  schedule_expression = var.schedule_expression
  target_arn = module.patch_lambda.lambda_arn
  input = jsonencode(var.event_input)
  tags = var.tags
}

output "lambda_function_arn" {
  value = module.patch_lambda.lambda_arn
}

output "reports_bucket_name" {
  value = module.reports_bucket.bucket_id
}

output "recipients_table_name" {
  value = module.recipients_table.table_name
}
