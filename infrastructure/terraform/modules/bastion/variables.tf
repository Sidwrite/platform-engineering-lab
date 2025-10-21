# Bastion Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "security_group_id" {
  description = "ID of the bastion security group"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the bastion host"
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

variable "public_key" {
  description = "Public key content"
  type        = string
  default     = ""
}
