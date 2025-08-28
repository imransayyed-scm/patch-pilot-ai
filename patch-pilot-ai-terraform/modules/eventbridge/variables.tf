variable "name" { type = string }
variable "schedule_expression" { type = string }
variable "description" { type = string, default = "" }
variable "target_arn" { type = string }
variable "input" { type = string, default = "" }
variable "tags" { type = map(string), default = {} }
