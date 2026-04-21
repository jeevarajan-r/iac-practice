# terraform {
#   backend "s3" {
#     bucket       = "image-upload-demo-12345"
#     key          = "state/terraform.tfstate"
#     region       = "us-east-1"
#     use_lockfile = true
#     encrypt      = true
#   }
# }

provider "aws" {
  region = "us-east-1"
}

# 1. SHARED NETWORKING
module "networking" {
  source       = "./networking"
  project_name = var.project_name
}

# 2. WRITER PHASE (Graph DB & Data Ingestion)
module "writer_phase" {
  source             = "./writer-phase"
  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  neptune_subnet_ids = module.networking.private_subnet_ids
  neptune_sg_id      = module.networking.neptune_sg_id
}

# 3. READER PHASE (Frontend Chat App)
module "reader_phase" {
  source           = "./reader-phase"
  project_name     = var.project_name
  vpc_id           = module.networking.vpc_id
  public_subnet_id = module.networking.public_subnet_ids[0]
  chat_app_sg_id   = module.networking.chat_app_sg_id
  neptune_endpoint = module.writer_phase.neptune_endpoint
}

# 4. MONITORING (CloudWatch Dashboard for Phase 1 & 2)
module "monitoring" {
  source             = "./monitoring"
  project_name       = var.project_name
  ec2_instance_id    = module.reader_phase.instance_id
  neptune_cluster_id = module.writer_phase.neptune_cluster_id
}

# ============================================================
# OUTPUTS
# ============================================================

output "elastic_ip_endpoint" {
  value       = module.reader_phase.chat_app_public_ip
  description = "The static Elastic IP where the chat app is hosted"
}

output "neptune_endpoint" {
  value       = module.writer_phase.neptune_endpoint
  description = "The endpoint for the Neptune cluster"
}

output "s3_bucket_name" {
  value       = module.writer_phase.cpg_s3_bucket
  description = "The name of the S3 bucket for CPG storage"
}

output "s3_bucket_arn" {
  value       = module.writer_phase.cpg_s3_bucket_arn
  description = "The ARN of the S3 bucket for CPG storage"
}

output "lambda_function_name" {
  value       = module.writer_phase.lambda_function_name
  description = "The name of the Neptune loader Lambda function"
}
