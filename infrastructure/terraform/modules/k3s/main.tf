# K3s Cluster Module
# Deploys k3s on EC2 instance for container orchestration

# Data source for AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 instance for k3s cluster
resource "aws_instance" "k3s_master" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro" # Free Tier compliant
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name != "" ? var.key_name : null
  user_data = templatefile("${path.module}/user_data.sh", {
    cluster_name = var.cluster_name
    environment  = var.environment
  })
  ebs_optimized        = true
  iam_instance_profile = aws_iam_instance_profile.k3s.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "${var.environment}-k3s-master-root"
    }
  }

  tags = {
    Name = "${var.environment}-k3s-master"
    Type = "K3s-Master"
  }
}

# Security group for k3s
resource "aws_security_group" "k3s" {
  name_prefix = "${var.environment}-k3s-"
  description = "Security group for K3s cluster"
  vpc_id      = var.vpc_id

  # K3s API server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    description = "K3s API server"
  }

  # K3s node communication
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    description = "K3s node communication"
  }

  # K3s flannel VXLAN
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    description = "K3s flannel VXLAN"
  }

  # K3s metrics server
  ingress {
    from_port   = 10248
    to_port     = 10248
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    description = "K3s metrics server"
  }

  # SSH access from bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
    description     = "SSH from bastion"
  }

  # HTTP/HTTPS for application access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # VPC CIDR
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.environment}-k3s-sg"
  }
}

# IAM role for k3s
resource "aws_iam_role" "k3s" {
  name = "${var.environment}-k3s-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-k3s-role"
  }
}

# IAM policy for k3s
resource "aws_iam_role_policy" "k3s" {
  name = "${var.environment}-k3s-policy"
  role = aws_iam_role.k3s.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach IAM role to instance
resource "aws_iam_instance_profile" "k3s" {
  name = "${var.environment}-k3s-profile"
  role = aws_iam_role.k3s.name

  tags = {
    Name = "${var.environment}-k3s-profile"
  }
}

# Attach profile to instance (using iam_instance_profile in the instance resource)
# Note: IAM instance profile attachment is handled in the instance resource itself
