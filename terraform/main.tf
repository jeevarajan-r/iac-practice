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
  # ami           = "ami-0f5ee92e2d63afc18" # Amazon Linux 2 (verify)
  # instance_type = "t2.micro"

  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = var.instance_name
  }
  
  user_data = <<-EOF
              #!/bin/bash
              yum install -y python3
              EOF
}