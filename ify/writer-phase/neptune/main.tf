variable "subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "loader_role_arn" { type = string }

resource "aws_neptune_subnet_group" "main" {
  name       = "ify-neptune-subnet-group"
  subnet_ids = var.subnet_ids
}

# resource "aws_neptune_cluster" "main" {
#   cluster_identifier      = "ify-neptune-cluster"
#   engine                  = "neptune"
#   engine_version          = "1.4.7.0"
#   neptune_subnet_group_name = aws_neptune_subnet_group.main.name
#   vpc_security_group_ids  = var.security_group_ids
#   
#   iam_roles               = [var.loader_role_arn]
#   
#   backup_retention_period = 5
#   skip_final_snapshot     = true
#   storage_type            = "iopt1" # I/O Optimized to save costs
# }
# 
# resource "aws_neptune_cluster_instance" "writer" {
#   cluster_identifier      = "ify-neptune-cluster" # hardcoded id instead of interpolation just for comments
#   instance_class          = "db.r8g.2xlarge"
#   engine                  = "neptune"
#   engine_version          = "1.4.7.0"
# }

output "neptune_endpoint" {
  value = "neptune-temporarily-disabled-for-testing"
}

output "neptune_cluster_id" {
  value = "dummy-neptune-cluster-id"
}
