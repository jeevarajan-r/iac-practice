resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "ify-shared-vpc" }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway for the Public Subnet (EC2 Reader Phase)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "ify-igw" }
}

# Public Subnet for the EC2 UI
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "ify-public-subnet-${count.index}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "ify-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnet for Neptune (Writer Phase)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2) # offset by 2 to avoid collision
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = { Name = "ify-private-subnet-${count.index}" }
}

# Security Group for the Reader Chat App (EC2)
resource "aws_security_group" "chat_app_sg" {
  name        = "chat-app-sg"
  description = "Allow inbound traffic to chat app on 8080 and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open SSH for GitHub runner configuration logging if needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "ify-chat-app-sg" }
}

# Security Group for Neptune (Writer Phase)
resource "aws_security_group" "neptune_sg" {
  name        = "neptune-cluster-sg"
  description = "Security group for Neptune Cluster"
  vpc_id      = aws_vpc.main.id

  # Allow Neptune port from the entire VPC so the EC2 reader can query it
  ingress {
    from_port       = 8182
    to_port         = 8182
    protocol        = "tcp"
    security_groups = [aws_security_group.chat_app_sg.id]
  }
  
  # Allow traffic from within its own subnets / anywhere in VPC just in case
  ingress {
    from_port   = 8182
    to_port     = 8182
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "ify-neptune-sg" }
}

# --- Outputs ---
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "chat_app_sg_id" {
  value = aws_security_group.chat_app_sg.id
}

output "neptune_sg_id" {
  value = aws_security_group.neptune_sg.id
}
