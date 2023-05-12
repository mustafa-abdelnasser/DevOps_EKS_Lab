
output "iam_awslbcRole_arn" {
  value = aws_iam_role.awslbcRole.arn
}

output "iam_awslbcPolicy_arn" {
  value = aws_iam_policy.awslbcPolicy.arn
}

