# K3s Module Variables

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for k3s instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for k3s instance"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Bastion security group ID for SSH access"
  type        = string
}

variable "key_name" {
  description = "SSH key name"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "K3s cluster name"
  type        = string
  default     = "pet-project-cluster"
}
