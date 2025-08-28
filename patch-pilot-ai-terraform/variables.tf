variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project/app name prefix"
  type        = string
  default     = "patch-pilot-backend"
}

variable "llm_api_key" {
  description = "API key for the external LLM (Gemini/OpenAI)"
  type        = string
  sensitive   = true
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.9" # keep aligned with your current code; change to python3.11/3.12 when ready
}

variable "lambda_timeout" {
  description = "Lambda timeout (seconds)"
  type        = number
  default     = 30
}

variable "lambda_memory" {
  description = "Lambda memory (MB)"
  type        = number
  default     = 256
}

variable "src_get_findings" {
  description = "Path to the get_findings source folder"
  type        = string
  default     = "src/get_findings"
}

variable "src_analyze_finding" {
  description = "Path to the analyze_finding source folder"
  type        = string
  default     = "src/analyze_finding"
}

variable "src_deploy_fix" {
  description = "Path to the deploy_fix source folder"
  type        = string
  default     = "src/deploy_fix"
}
