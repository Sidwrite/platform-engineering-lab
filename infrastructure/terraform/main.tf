# Pet Project Infrastructure - Assignment 1
# Cloud Infrastructure Setup with Terraform

# Terraform configuration moved to versions.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "pet-project"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Generate SSH Key Pair
resource "tls_private_key" "pet_project_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "pet_project_ssh_key_kp" {
  key_name   = "pet-project-ssh-key-kp"
  public_key = tls_private_key.pet_project_ssh_key.public_key_openssh

  tags = {
    Name        = "pet-project-ssh-key"
    Environment = var.environment
    Project     = "pet-project"
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.pet_project_ssh_key.private_key_pem
  filename        = "${path.module}/pet-project-ssh-key.pem"
  file_permission = "0400"
}

resource "local_file" "public_key" {
  content         = tls_private_key.pet_project_ssh_key.public_key_openssh
  filename        = "${path.module}/pet-project-ssh-key.pub"
  file_permission = "0644"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environment          = var.environment
}

# Security Groups
module "security_groups" {
  source = "./modules/security_groups"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

# RDS PostgreSQL Database
module "database" {
  source = "./modules/database"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security_groups.database_sg_id
  environment        = var.environment
  db_instance_class  = var.db_instance_class
  allocated_storage  = var.allocated_storage
}

# Bastion Host (Jumpbox)
module "bastion" {
  source = "./modules/bastion"

  vpc_id            = module.vpc.vpc_id
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  security_group_id = module.security_groups.bastion_sg_id
  ami_id            = data.aws_ami.amazon_linux.id
  environment       = var.environment
  key_name          = aws_key_pair.pet_project_ssh_key_kp.key_name
}

# Application Server
module "app_server" {
  source = "./modules/app_server"

  vpc_id            = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_ids[0]
  security_group_id = module.security_groups.app_sg_id
  ami_id            = data.aws_ami.amazon_linux.id
  environment       = var.environment
  key_name          = aws_key_pair.pet_project_ssh_key_kp.key_name
  db_endpoint       = module.database.db_endpoint
}

# Monitoring and Security (commented out for minimal setup)
# module "monitoring" {
#   source = "./modules/monitoring"
#   
#   environment     = var.environment
#   app_instance_id = module.app_server.app_instance_id
#   db_instance_id  = module.database.db_instance_id
# }

# Budget and Cost Control (commented out for minimal setup)
# module "budget" {
#   source = "./modules/budget"
#   
#   environment   = var.environment
#   budget_email  = var.budget_email
# }

# K3s Cluster for Application Deployment
module "k3s" {
  source = "./modules/k3s"

  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnet_id         = module.vpc.private_subnet_ids[0]
  security_group_id         = module.security_groups.app_sg_id
  bastion_security_group_id = module.security_groups.bastion_sg_id
  key_name                  = aws_key_pair.pet_project_ssh_key_kp.key_name
  cluster_name              = "pet-project-cluster"
}
