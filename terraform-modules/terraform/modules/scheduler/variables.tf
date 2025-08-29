variable "schedule_name" { type = string }
variable "target_lambda_arn" { type = string }
variable "tags" { type = map(string); default = {} }