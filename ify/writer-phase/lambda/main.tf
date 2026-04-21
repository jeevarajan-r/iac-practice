variable "lambda_role_arn" { type = string }
variable "neptune_endpoint" { type = string }
variable "loader_s3_bucket" { type = string }
variable "loader_s3_bucket_arn" { type = string }
variable "neptune_loader_iam_role_arn" { type = string }
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }

resource "aws_lambda_function" "cpg_loader" {
  function_name = "ify-trigger-neptune-loader-mb"
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler" # File is lambda_function.py, handler is lambda_handler
  role          = var.lambda_role_arn
  
  filename      = "${path.root}/writer-phase/lambda/cpg_loader.zip"

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
