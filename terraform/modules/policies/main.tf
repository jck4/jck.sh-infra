# FoundryVTT Spot Instance Lambda Policy
data "aws_iam_policy_document" "foundry_spot_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeImages"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:RequestSpotInstances",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:RunInstances",
      "ec2:AttachVolume",
      "ec2:DescribeVolumes"

    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListHostedZonesByName"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeInstances",
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:ssm:us-east-1:940908754875:parameter/cloudfront_key"
    ]
  }


}


# Create the policies
resource "aws_iam_policy" "foundry_spot_lambda" {
  name        = "${var.name_prefix}foundry-spot-lambda-policy"
  description = "Policy for Lambda function to launch FoundryVTT spot instances"
  policy      = data.aws_iam_policy_document.foundry_spot_lambda.json
}
