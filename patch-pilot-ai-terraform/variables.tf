variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "reports_bucket_name" {
  type = string
  default = "patch-pilot-reports-bucket"
}

variable "recipients_table_name" {
  type = string
  default = "patch-pilot-recipients"
}

variable "lambda_role_name" {
  type = string
  default = "patch_pilot_lambda_role"
}

variable "lambda_function_name" {
  type = string
  default = "patch_pilot_lambda"
}

variable "lambda_handler" {
  type = string
  default = "index.lambda_handler"
}

variable "lambda_runtime" {
  type = string
  default = "python3.12"
}

variable "lambda_code_s3_bucket" {
  type = string
  default = ""
  description = "S3 bucket containing lambda deployment zip. If empty, provide local deploy method."
}

variable "lambda_code_s3_key" {
  type = string
  default = ""
  description = "S3 key for the lambda zip object."
}

variable "lambda_environment" {
  type = map(string)
  default = {}
}

variable "ses_sender_email" {
  type = string
  default = "noreply@example.com"
}

variable "event_rule_name" {
  type = string
  default = "patch-pilot-schedule"
}

variable "schedule_expression" {
  type = string
  default = "cron(30 15 ? * MON-THU *)"
}

variable "event_input" {
  type = map(any)
  default = {}
}
