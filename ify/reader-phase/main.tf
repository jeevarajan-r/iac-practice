variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_id" { type = string }
variable "chat_app_sg_id" { type = string }
variable "neptune_endpoint" { type = string }

module "ec2" {
  source           = "./ec2"
  project_name     = var.project_name
  vpc_id           = var.vpc_id
  public_subnet_id = var.public_subnet_id
  chat_app_sg_id   = var.chat_app_sg_id
  neptune_endpoint = var.neptune_endpoint
}

output "chat_app_public_ip" {
  value = module.ec2.public_ip
}

output "chat_app_private_key_pem" {
  value     = module.ec2.private_key_pem
  sensitive = true
}

output "instance_id" {
  value = module.ec2.instance_id
}
