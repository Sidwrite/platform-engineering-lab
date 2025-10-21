# App Server Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet"
  type        = string
}

# variable "public_subnet_ids" removed - ALB not used in free tier

variable "security_group_id" {
  description = "ID of the application security group"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the application server"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = ""
}

variable "db_endpoint" {
  description = "Database endpoint"
  type        = string
}
