output "role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "role_id" {
  value = aws_iam_role.lambda_role.id
}
