# Use policies module
module "policies" {
  source = "../policies"
  name_prefix = "lambda-"
}

# Create Lambda function
resource "aws_lambda_function" "spot_launcher" {
  filename         = "${path.module}/ec2_spot_lambda.zip"
  function_name    = "foundry-spot-launcher"
  role            = var.lambda_role_arn
  handler         = "ec2_spot_lambda.lambda_handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      INSTANCE_TYPE = "t3.micro"
    }
  }
}

resource "aws_lambda_permission" "allow_invoke" {
  statement_id  = "AllowInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spot_launcher.function_name
  principal     = "lambda.amazonaws.com"
} 