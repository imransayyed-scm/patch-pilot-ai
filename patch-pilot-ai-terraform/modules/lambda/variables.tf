variable "function_name" { type = string }
variable "handler" { type = string }
variable "runtime" { type = string }
variable "role_arn" { type = string }
variable "s3_bucket_for_code" { type = string, default = "" }
variable "s3_key_for_code" { type = string, default = "" }
variable "environment" { type = map(string), default = {} }
variable "timeout" { type = number, default = 60 }
variable "memory_size" { type = number, default = 128 }
variable "event_rule_arn" { type = string, default = "" }
variable "tags" { type = map(string), default = {} }
