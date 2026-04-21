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
  source = "./networking"
}

# 2. WRITER PHASE (Graph DB & Data Ingestion)
module "writer_phase" {
  source             = "./writer-phase"
  vpc_id             = module.networking.vpc_id
  neptune_subnet_ids = module.networking.private_subnet_ids
  neptune_sg_id      = module.networking.neptune_sg_id
}

# 3. READER PHASE (Frontend Chat App)
module "reader_phase" {
  source           = "./reader-phase"
  vpc_id           = module.networking.vpc_id
  public_subnet_id = module.networking.public_subnet_ids[0]
  chat_app_sg_id   = module.networking.chat_app_sg_id
  neptune_endpoint = module.writer_phase.neptune_endpoint
}

# 4. MONITORING (CloudWatch Dashboard for Phase 1 & 2)
module "monitoring" {
  source             = "./monitoring"
  ec2_instance_id    = module.reader_phase.instance_id
  neptune_cluster_id = module.writer_phase.neptune_cluster_id
}

# ============================================================
# OUTPUTS
# ============================================================

output "chat_app_public_ip" {
  value = module.reader_phase.chat_app_public_ip
  description = "The Public IP where the chat app will be hosted on port 8080"
}

output "neptune_endpoint" {
  value = module.writer_phase.neptune_endpoint
}

output "cpg_s3_bucket" {
  value = module.writer_phase.cpg_s3_bucket
}
