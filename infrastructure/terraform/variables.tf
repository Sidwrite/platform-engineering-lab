# Variables for Knova Fintech Infrastructure

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

# SSH key_name variable removed - keys are now auto-generated

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # Free tier eligible
}

variable "allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20 # Free tier eligible
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "pet_project"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "pet_admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "budget_email" {
  description = "Email for budget notifications"
  type        = string
  default     = "admin@example.com"
}
