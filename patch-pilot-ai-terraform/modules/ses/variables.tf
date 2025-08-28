variable "email_identity" { type = string }
variable "region" { type = string, default = "us-east-1" }
variable "tags" { type = map(string), default = {} }
