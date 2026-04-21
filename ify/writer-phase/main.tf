variable "vpc_id" {}
variable "neptune_subnet_ids" { type = list(string) }
variable "neptune_sg_id" { type = string }

module "iam" {
  source = "./iam"
}

module "s3" {
  source = "./s3"
}

module "neptune" {
  source             = "./neptune"
  subnet_ids         = var.neptune_subnet_ids
  security_group_ids = [var.neptune_sg_id]
  loader_role_arn    = module.iam.neptune_s3_loader_role_arn
}

module "lambda" {
  source                      = "./lambda"
  subnet_ids                  = var.neptune_subnet_ids
  security_group_ids          = [var.neptune_sg_id]
  lambda_role_arn             = module.iam.lambda_role_arn
  neptune_endpoint            = module.neptune.neptune_endpoint
  loader_s3_bucket            = module.s3.bucket_name
  loader_s3_bucket_arn        = module.s3.bucket_arn
  neptune_loader_iam_role_arn = module.iam.neptune_s3_loader_role_arn
}

output "neptune_endpoint" {
  value = module.neptune.neptune_endpoint
}

output "neptune_cluster_id" {
  value = module.neptune.neptune_cluster_id
}

output "cpg_s3_bucket" {
  value = module.s3.bucket_name
}
