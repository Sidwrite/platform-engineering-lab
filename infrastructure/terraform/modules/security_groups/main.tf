# Security Groups Module for Knova Fintech

# Bastion Security Group
resource "aws_security_group" "bastion" {
  name_prefix = "${var.environment}-pet-bastion-"
  vpc_id      = var.vpc_id

  # SSH access from anywhere (for demo purposes)
  # In production, restrict to specific IPs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-pet-bastion-sg"
  }
}

# Application Server Security Group
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-pet-app-"
  vpc_id      = var.vpc_id

  # SSH access from bastion only
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # HTTP access from anywhere (for demo)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere (for demo)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-pet-app-sg"
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name_prefix = "${var.environment}-pet-db-"
  vpc_id      = var.vpc_id

  # PostgreSQL access from app servers only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # PostgreSQL access from bastion (for maintenance)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-pet-db-sg"
  }
}
