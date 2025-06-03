module "policies" {
  source = "../policies"
}

# Create Lambda role
resource "aws_iam_role" "lambda" {
  name = "foundry-spot-launcher"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach Foundry spot Lambda policy
resource "aws_iam_role_policy_attachment" "foundry_spot" {
  role       = aws_iam_role.lambda.name
  policy_arn = module.policies.foundry_spot_lambda_policy_arn
}