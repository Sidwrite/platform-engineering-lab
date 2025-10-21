# Main Terraform Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "app_private_ip" {
  description = "Private IP of the application server"
  value       = module.app_server.app_private_ip
}

# ALB outputs removed - not using ALB in free tier

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_endpoint
}

output "database_port" {
  description = "RDS instance port"
  value       = module.database.db_port
}

output "ssh_connection_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i pet-project-ssh-key.pem ec2-user@${module.bastion.bastion_public_ip}"
}

output "ssh_key_name" {
  description = "Name of the generated SSH key pair"
  value       = aws_key_pair.pet_project_ssh_key_kp.key_name
}

output "private_key_path" {
  description = "Path to the generated private key file"
  value       = "${path.module}/pet-project-ssh-key.pem"
}

output "public_key_path" {
  description = "Path to the generated public key file"
  value       = "${path.module}/pet-project-ssh-key.pub"
}

output "application_url" {
  description = "URL to access the application (via bastion host)"
  value       = "http://${module.app_server.app_private_ip}"
}

# K3s Cluster Outputs
output "k3s_instance_id" {
  description = "K3s master instance ID"
  value       = module.k3s.k3s_instance_id
}

output "k3s_private_ip" {
  description = "K3s master private IP"
  value       = module.k3s.k3s_private_ip
}

output "k3s_ssh_command" {
  description = "SSH command to connect to k3s master"
  value       = module.k3s.k3s_ssh_command
}

output "k3s_kubeconfig_command" {
  description = "Command to get kubeconfig"
  value       = module.k3s.k3s_kubeconfig_command
}
