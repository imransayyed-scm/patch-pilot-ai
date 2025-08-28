variable "role_name" {
  type = string
}

variable "inline_policy" {
  type = string
  default = ""
  description = "Optional JSON policy to attach as inline policy. If empty, module uses a default permissive policy (adjust for production)."
}

variable "tags" {
  type = map(string)
  default = {}
}
