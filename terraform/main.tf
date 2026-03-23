# ─────────────────────────────────────────────
#  Two-Tier Web App — AWS Free Tier Safe
#  Flask (EC2 t3.micro) + DynamoDB
# ─────────────────────────────────────────────

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── Variables ───────────────────────────────
variable "aws_region" {
  default = "us-east-1"
}

variable "key_pair_name" {
  description = "Name of your existing EC2 Key Pair (create in AWS Console → EC2 → Key Pairs)"
  type        = string
}

variable "app_name" {
  default = "visitor-register"
}

# ─── DynamoDB Table ──────────────────────────
resource "aws_dynamodb_table" "visitors" {
  name         = "VisitorNames"
  billing_mode = "PAY_PER_REQUEST"   # FREE TIER — no provisioned capacity charges
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.app_name}-table"
  }
}

# ─── IAM Role for EC2 → DynamoDB ─────────────
resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "dynamo_policy" {
  name = "${var.app_name}-dynamo-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:Scan",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem"
      ]
      Resource = aws_dynamodb_table.visitors.arn
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-profile"
  role = aws_iam_role.ec2_role.name
}

# ─── VPC & Networking ─────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.app_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.app_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = { Name = "${var.app_name}-subnet" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.app_name}-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ─── Security Group ───────────────────────────
resource "aws_security_group" "web_sg" {
  name        = "${var.app_name}-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Flask direct (optional)"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # Restrict to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-sg" }
}

# ─── EC2 — Amazon Linux 2023 (Free Tier t3.micro) ───
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro" # Free Tier eligible
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_pair_name

 user_data = base64encode(file("${path.module}\\user_data.sh"))

  tags = { Name = "${var.app_name}-server" }
}

# ─── Outputs ─────────────────────────────────
output "website_url" {
  value       = "http://${aws_instance.web.public_ip}"
  description = "Open this URL in your browser after ~2 min"
}

output "ssh_command" {
  value       = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.web.public_ip}"
  description = "SSH into the server"
}

output "dynamodb_table" {
  value       = aws_dynamodb_table.visitors.name
  description = "DynamoDB table name"
}
