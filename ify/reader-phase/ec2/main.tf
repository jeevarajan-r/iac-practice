variable "vpc_id" { type = string }
variable "public_subnet_id" { type = string }
variable "chat_app_sg_id" { type = string }
variable "neptune_endpoint" { type = string }

# Fetch the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create an SSH Key pair dynamically or use existing. We will just use TLS to generate one.
resource "tls_private_key" "ify_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ify_key" {
  key_name   = "ify-chat-app-key"
  public_key = tls_private_key.ify_key.public_key_openssh
}

resource "aws_instance" "app_runner" {
  ami                         = data.aws_ami.ubuntu.id
  # instance_type               = "t3.medium" # Need at least 4GB RAM for a good docker-compose stack
  instance_type               = "t2.micro" # For testing
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.chat_app_sg_id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ify_key.key_name

  root_block_device {
    volume_size = 8 # For testing
    volume_type = "gp2" # For testing
    # volume_size = 30 # standard 8GB is sometimes too small for docker builds
    # volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              # 1. Update and install dependencies
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release git

              # 2. Install Docker
              mkdir -m 0755 -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # 3. Add ubuntu user to docker group
              usermod -aG docker ubuntu

              # 4. Prepare environment file
              # We inject the Neptune endpoint so the chat app containers can use it
              cat << 'ENVFILE' > /home/ubuntu/.env.example
              NEPTUNE_ENDPOINT=${var.neptune_endpoint}
              NEPTUNE_PORT=8182
              AWS_REGION=us-east-1
              ENVFILE
              chown ubuntu:ubuntu /home/ubuntu/.env.example

              # 5. Enable Docker on boot
              systemctl enable docker
              systemctl start docker

              # NOTE: To complete the CI/CD pipeline, you will need to SSH into this instance 
              # and run the GitHub Actions Runner configuration script as the 'ubuntu' user.
              # Be sure your docker-compose.yml uses `restart: always` so the app survives reboots!
              EOF

  tags = {
    Name = "ify-runner-app"
  }
}

# Allocate and associate an Elastic IP so the IP doesn't change on reboot
resource "aws_eip" "ify_ip" {
  instance = aws_instance.app_runner.id
  domain   = "vpc"
}

output "public_ip" {
  value = aws_eip.ify_ip.public_ip
}

output "private_key_pem" {
  value     = tls_private_key.ify_key.private_key_pem
  sensitive = true
}

output "instance_id" {
  value = aws_instance.app_runner.id
}
