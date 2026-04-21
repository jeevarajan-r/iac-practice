variable "project_name" { type = string }
variable "lambda_role_arn" { type = string }
variable "neptune_endpoint" { type = string }
variable "loader_s3_bucket" { type = string }
variable "loader_s3_bucket_arn" { type = string }
variable "neptune_loader_iam_role_arn" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/lambda_function.py"
  output_path = "${path.module}/cpg_loader.zip"
}

resource "aws_lambda_function" "cpg_loader" {
  function_name = "${var.project_name}-trigger-neptune-loader-mb"
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler"
  role          = var.lambda_role_arn
  
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }
  
  environment {
    variables = {
      NEPTUNE_LOADER_ENDPOINT_URL = "https://${var.neptune_endpoint}:8182"
      NEPTUNE_IAM_ROLE_ARN        = var.neptune_loader_iam_role_arn
    }
  }
}

output "lambda_function_name" {
  value = aws_lambda_function.cpg_loader.function_name
}
