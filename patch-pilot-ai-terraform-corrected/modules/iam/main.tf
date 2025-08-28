data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
  tags = var.tags
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid = "CloudWatchLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid = "DynamoDB"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem"
    ]
    resources = ["*"] 
  }

  statement {
    sid = "S3"
    actions = ["s3:PutObject","s3:GetObject","s3:ListBucket"]
    resources = ["*"] 
  }

  statement {
    sid = "InspectorRead"
    actions = ["inspector2:ListFindings","inspector2:GetFindings","inspector2:ListFindingAggregations"]
    resources = ["*"] 
  }

  statement {
    sid = "SSMRunCommand"
    actions = [
      "ssm:SendCommand",
      "ssm:GetCommandInvocation",
      "ssm:ListCommands",
      "ssm:ListCommandInvocations"
    ]
    resources = ["*"] 
  }

  statement {
    sid = "SES"
    actions = ["ses:SendEmail","ses:SendRawEmail"]
    resources = ["*"] 
  }
}

resource "aws_iam_role_policy" "lambda_inline" {
  name = "${var.role_name}-policy"
  role = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}
