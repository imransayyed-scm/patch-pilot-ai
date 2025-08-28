locals {
  table_name     = "${var.project_name}-findings"
  api_name       = "${var.project_name}-api"
  role_name_base = "${var.project_name}-lambda-role"
}

# -------------------------------------------------------------------
# DynamoDB Table
# -------------------------------------------------------------------
resource "aws_dynamodb_table" "findings" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}

# -------------------------------------------------------------------
# IAM Role & Policies for Lambdas
# -------------------------------------------------------------------
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = local.role_name_base
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

# Basic logs policy
data "aws_iam_policy_document" "cw_logs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cw_logs" {
  name        = "${var.project_name}-cw-logs"
  description = "CloudWatch logs for Lambdas"
  policy      = data.aws_iam_policy_document.cw_logs.json
}

resource "aws_iam_role_policy_attachment" "cw_logs_attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.cw_logs.arn
}

# DynamoDB CRUD policy (table-scoped)
data "aws_iam_policy_document" "ddb_crud" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DeleteItem"
    ]
    resources = [
      aws_dynamodb_table.findings.arn,
      "${aws_dynamodb_table.findings.arn}/index/*"
    ]
  }
}

resource "aws_iam_policy" "ddb_crud" {
  name   = "${var.project_name}-ddb-crud"
  policy = data.aws_iam_policy_document.ddb_crud.json
}

resource "aws_iam_role_policy_attachment" "ddb_crud_attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.ddb_crud.arn
}

# Inspector Read policy (list findings)
data "aws_iam_policy_document" "inspector_read" {
  statement {
    actions   = ["inspector2:ListFindings", "inspector2:BatchGetFindingDetails", "inspector2:GetFindingsReportStatus"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "inspector_read" {
  name   = "${var.project_name}-inspector-read"
  policy = data.aws_iam_policy_document.inspector_read.json
}

resource "aws_iam_role_policy_attachment" "inspector_read_attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.inspector_read.arn
}

# SSM SendCommand policy (broad for hackathon; scope later)
data "aws_iam_policy_document" "ssm_send_command" {
  statement {
    actions   = ["ssm:SendCommand"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ssm_send_command" {
  name   = "${var.project_name}-ssm-send"
  policy = data.aws_iam_policy_document.ssm_send_command.json
}

resource "aws_iam_role_policy_attachment" "ssm_send_attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.ssm_send_command.arn
}

# -------------------------------------------------------------------
# Package Lambda sources (zip)
# -------------------------------------------------------------------
data "archive_file" "get_findings_pkg" {
  type        = "zip"
  source_dir  = var.src_get_findings
  output_path = "${path.module}/dist/get_findings.zip"
}

data "archive_file" "analyze_finding_pkg" {
  type        = "zip"
  source_dir  = var.src_analyze_finding
  output_path = "${path.module}/dist/analyze_finding.zip"
}

data "archive_file" "deploy_fix_pkg" {
  type        = "zip"
  source_dir  = var.src_deploy_fix
  output_path = "${path.module}/dist/deploy_fix.zip"
}

# -------------------------------------------------------------------
# Lambda Functions
# -------------------------------------------------------------------
resource "aws_lambda_function" "get_findings" {
  function_name = "${var.project_name}-get-findings"
  role          = aws_iam_role.lambda.arn
  handler       = "app.lambda_handler"
  runtime       = var.lambda_runtime
  filename      = data.archive_file.get_findings_pkg.output_path
  source_code_hash = data.archive_file.get_findings_pkg.output_base64sha256
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.findings.name
    }
  }

  depends_on = [aws_iam_role_policy_attachment.cw_logs_attach]
}

resource "aws_lambda_function" "analyze_finding" {
  function_name = "${var.project_name}-analyze-finding"
  role          = aws_iam_role.lambda.arn
  handler       = "app.lambda_handler"
  runtime       = var.lambda_runtime
  filename      = data.archive_file.analyze_finding_pkg.output_path
  source_code_hash = data.archive_file.analyze_finding_pkg.output_base64sha256
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  environment {
    variables = {
      TABLE_NAME  = aws_dynamodb_table.findings.name
      LLM_API_KEY = var.llm_api_key
    }
  }

  depends_on = [aws_iam_role_policy_attachment.cw_logs_attach]
}

resource "aws_lambda_function" "deploy_fix" {
  function_name = "${var.project_name}-deploy-fix"
  role          = aws_iam_role.lambda.arn
  handler       = "app.lambda_handler"
  runtime       = var.lambda_runtime
  filename      = data.archive_file.deploy_fix_pkg.output_path
  source_code_hash = data.archive_file.deploy_fix_pkg.output_base64sha256
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.findings.name
    }
  }

  depends_on = [aws_iam_role_policy_attachment.cw_logs_attach]
}

# -------------------------------------------------------------------
# API Gateway (REST) with resources & methods
# Routes:
#   GET    /findings                          -> get_findings
#   POST   /findings/{findingId}/analyze      -> analyze_finding
#   POST   /findings/{findingId}/deploy       -> deploy_fix
# -------------------------------------------------------------------
resource "aws_api_gateway_rest_api" "api" {
  name        = local.api_name
  description = "Patch Pilot AI backend API"
}

# /findings
resource "aws_api_gateway_resource" "findings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "findings"
}

# /findings/{findingId}
resource "aws_api_gateway_resource" "finding_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.findings.id
  path_part   = "{findingId}"
}

# /findings/{findingId}/analyze
resource "aws_api_gateway_resource" "analyze" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.finding_id.id
  path_part   = "analyze"
}

# /findings/{findingId}/deploy
resource "aws_api_gateway_resource" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.finding_id.id
  path_part   = "deploy"
}

# Methods
resource "aws_api_gateway_method" "get_findings" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.findings.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "post_analyze" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.analyze.id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.findingId" = true
  }
}

resource "aws_api_gateway_method" "post_deploy" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.deploy.id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.findingId" = true
  }
}

# Lambda Integrations
resource "aws_api_gateway_integration" "get_findings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.findings.id
  http_method = aws_api_gateway_method.get_findings.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.get_findings.invoke_arn
}

resource "aws_api_gateway_integration" "post_analyze" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.analyze.id
  http_method = aws_api_gateway_method.post_analyze.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.analyze_finding.invoke_arn
  request_parameters = {
    "integration.request.path.findingId" = "method.request.path.findingId"
  }
}

resource "aws_api_gateway_integration" "post_deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.deploy.id
  http_method = aws_api_gateway_method.post_deploy.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.deploy_fix.invoke_arn
  request_parameters = {
    "integration.request.path.findingId" = "method.request.path.findingId"
  }
}

# Lambda permissions so API Gateway can invoke them
resource "aws_lambda_permission" "allow_apigw_get_findings" {
  statement_id  = "AllowAPIGatewayInvokeGetFindings"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_findings.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_analyze" {
  statement_id  = "AllowAPIGatewayInvokeAnalyze"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analyze_finding.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_deploy" {
  statement_id  = "AllowAPIGatewayInvokeDeploy"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deploy_fix.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Deployment & Stage
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeploy = sha1(jsonencode({
      resources = [
        aws_api_gateway_resource.findings.id,
        aws_api_gateway_resource.finding_id.id,
        aws_api_gateway_resource.analyze.id,
        aws_api_gateway_resource.deploy.id
      ],
      methods = [
        aws_api_gateway_method.get_findings.id,
        aws_api_gateway_method.post_analyze.id,
        aws_api_gateway_method.post_deploy.id
      ],
      integrations = [
        aws_api_gateway_integration.get_findings.id,
        aws_api_gateway_integration.post_analyze.id,
        aws_api_gateway_integration.post_deploy.id
      ]
    }))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.get_findings,
    aws_api_gateway_integration.post_analyze,
    aws_api_gateway_integration.post_deploy
  ]
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "Prod"
  variables     = {}
}
