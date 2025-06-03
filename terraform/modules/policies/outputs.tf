output "foundry_spot_lambda_policy_arn" {
  description = "ARN of the policy for the FoundryVTT spot instance launcher Lambda function"
  value       = aws_iam_policy.foundry_spot_lambda.arn
}

