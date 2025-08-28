variable "role_name" { type = string }
variable "tags" { type = map(string), default = {} }
variable "attach_inspector_ssm" { type = bool, default = false }
