terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

# --- Backend Resources ---

module "dynamodb" {
  source     = "./modules/dynamodb_table"
  table_name = "${var.project_name}-findings-table"
  tags       = local.common_tags
}

module "get_findings_lambda" {
  source        = "./modules/lambda_function"
  function_name = "${var.project_name}-get-findings"
  code_path     = "./backend_code/get_findings/"
  table_arn     = module.dynamodb.table_arn
  tags          = local.common_tags
  iam_policy_statements = [{
    Effect   = "Allow",
    Action   = ["inspector2:ListFindings"],
    Resource = "*"
  }]
}

module "analyze_finding_lambda" {
  source        = "./modules/lambda_function"
  function_name = "${var.project_name}-analyze-finding"
  code_path     = "./backend_code/analyze_finding/"
  table_arn     = module.dynamodb.table_arn
  tags          = local.common_tags
  timeout_seconds = 60
  environment_variables = {
    LLM_API_KEY = var.llm_api_key
  }
}

module "deploy_fix_lambda" {
  source        = "./modules/lambda_function"
  function_name = "${var.project_name}-deploy-fix"
  code_path     = "./backend_code/deploy_fix/"
  table_arn     = module.dynamodb.table_arn
  tags          = local.common_tags
  iam_policy_statements = [{
    Effect   = "Allow",
    Action   = ["ssm:SendCommand"],
    Resource = "*"
  }]
}

module "scheduler" {
  source            = "./modules/scheduler"
  schedule_name     = "${var.project_name}-hourly-sync"
  target_lambda_arn = module.get_findings_lambda.function_arn
}

module "api_gateway" {
  source   = "./modules/api_gateway"
  api_name = "${var.project_name}-api"
  tags     = local.common_tags
  lambda_integrations = {
    "/findings"                       = { lambda_invoke_arn = module.get_findings_lambda.function_invoke_arn, http_method = "GET" },
    "/findings/{findingId}/analyze"   = { lambda_invoke_arn = module.analyze_finding_lambda.function_invoke_arn, http_method = "POST" },
    "/findings/{findingId}/deploy"    = { lambda_invoke_arn = module.deploy_fix_lambda.function_invoke_arn, http_method = "POST" }
  }
}

# --- Frontend Resources ---

module "frontend" {
  source             = "./modules/frontend_spa"
  bucket_name_prefix = "${var.project_name}-frontend"
  tags               = local.common_tags
}