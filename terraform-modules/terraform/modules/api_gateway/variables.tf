# modules/api_gateway/variables.tf
variable "api_name" { type = string }
variable "tags" { type = map(string) }
variable "lambda_integrations" {
  description = "A map of API paths to Lambda integration details."
  type = map(object({
    lambda_invoke_arn = string
    http_method       = string
  }))
}