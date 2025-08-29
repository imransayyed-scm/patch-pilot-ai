# variables.tf
variable "function_name" { type = string }
variable "code_path" { type = string }
variable "table_arn" { type = string }
variable "tags" { type = map(string) }
variable "timeout_seconds" { type = number; default = 30 }
variable "iam_policy_statements" { type = list(any); default = [] }
variable "environment_variables" { type = map(string); default = {} }