variable "site_bucket_name" { type = string }
variable "cloudfront_alias" { type = string, default = "" }
variable "tags" { type = map(string), default = {} }
