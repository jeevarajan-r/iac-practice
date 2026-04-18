terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"    
}
data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
      name = "name"
      values = [ "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" ]
    }

    owners = [ "099720109477" ]
  
}

resource "tls_private_key" "app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.ssh_key_name
  public_key = tls_private_key.app_key.public_key_openssh
}

resource "aws_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Allow SSH and App traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "uploads" {
  bucket = "image-upload-demo-12345"
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-upload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_policy" {
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:PutObject"]
      Resource = "${aws_s3_bucket.uploads.arn}/*"
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Force replacement of the instance if the user_data is changed
  user_data_replace_on_change = true

  tags = {
    Name = var.instance_name
  }
  
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3-pip git python3-venv

              # Clone application
              git clone ${var.github_url} /home/ubuntu/app
              
              # Navigate to the ACTUAL app folder
              cd /home/ubuntu/app/image-upload-app
              
              # Setup venv and dependencies
              python3 -m venv venv
              source venv/bin/activate
              pip install -r requirements.txt

              # Set Environment Variables
              export S3_BUCKET="${aws_s3_bucket.uploads.id}"
              export AWS_REGION="us-east-1"

              # Start Application
              nohup venv/bin/python app.py > app.log 2>&1 &
              EOF
}