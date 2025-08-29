resource "aws_iam_role" "scheduler_exec" {
  name = "${var.schedule_name}-exec-role"
  tags = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_policy" {
  name = "${var.schedule_name}-policy"
  role = aws_iam_role.scheduler_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "lambda:InvokeFunction",
      Resource = var.target_lambda_arn
    }]
  })
}

resource "aws_scheduler_schedule" "this" {
  name       = var.schedule_name
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 hour)"

  target {
    arn      = var.target_lambda_arn
    role_arn = aws_iam_role.scheduler_exec.arn
  }
}