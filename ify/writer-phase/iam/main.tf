variable "project_name" { type = string }

# 1. IAM Role for Neptune Bulk Loader to read from S3
resource "aws_iam_role" "neptune_s3_loader" {
  name = "${var.project_name}-NeptuneS3LoaderRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "s3_access_for_neptune" {
  name = "${var.project_name}-NeptuneS3Access"
  role = aws_iam_role.neptune_s3_loader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["s3:Get*", "s3:List*"]
      Effect = "Allow"
      Resource = "*" 
    }]
  })
}


# 2. IAM Role for the Lambda Loader
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-NeptuneLoaderLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-LambdaNeptuneS3Policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:Get*", "s3:List*"]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = ["neptune-db:*"]
        Effect = "Allow"
        Resource = "*"
      },
      {
         Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
         Effect = "Allow"
         Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DeleteNetworkInterface"]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Outputs
output "neptune_s3_loader_role_arn" {
  value = aws_iam_role.neptune_s3_loader.arn
}
output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}
