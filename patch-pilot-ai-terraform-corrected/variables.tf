variable "aws_region" { type = string, default = "ap-south-1" }
variable "tags" { type = map(string), default = {} }

variable "frontend_bucket_name" { type = string, default = "patch-pilot-frontend-bucket" }
variable "frontend_alias" { type = string, default = "" }

variable "dynamodb_table_name" { type = string, default = "patch-pilot-findings" }

variable "lambda_role_name" { type = string, default = "patch_pilot_lambda_role" }

variable "backend_lambda_name" { type = string, default = "patch-pilot-backend" }
variable "backend_handler" { type = string, default = "app.lambda_handler" }

variable "sync_lambda_name" { type = string, default = "patch-pilot-sync" }
variable "sync_handler" { type = string, default = "sync.lambda_handler" }

variable "lambda_runtime" { type = string, default = "python3.12" }
variable "lambda_code_s3_bucket" { type = string, default = "" }
variable "backend_lambda_s3_key" { type = string, default = "" }
variable "sync_lambda_s3_key" { type = string, default = "" }

variable "lambda_environment" { type = map(string), default = {} }
variable "gemini_api_key" { type = string, default = "" }

variable "api_name" { type = string, default = "patch-pilot-api" }

variable "schedule_name" { type = string, default = "patch-pilot-sync-schedule" }
variable "schedule_expression" { type = string, default = "rate(1 hour)" }
