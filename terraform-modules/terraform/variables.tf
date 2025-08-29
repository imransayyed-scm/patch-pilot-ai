variable "project_name" {
  description = "The name of the project, used for resource naming."
  type        = string
  default     = "patch-pilot"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
}

variable "llm_api_key" {
  description = "The secret API Key for the LLM (e.g., Google Gemini)."
  type        = string
  sensitive   = true
}