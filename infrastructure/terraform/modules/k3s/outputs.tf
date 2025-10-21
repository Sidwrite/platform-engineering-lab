# K3s Module Outputs

output "k3s_instance_id" {
  description = "K3s master instance ID"
  value       = aws_instance.k3s_master.id
}

output "k3s_private_ip" {
  description = "K3s master private IP"
  value       = aws_instance.k3s_master.private_ip
}

output "k3s_security_group_id" {
  description = "K3s security group ID"
  value       = aws_security_group.k3s.id
}

output "k3s_ssh_command" {
  description = "SSH command to connect to k3s master"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.k3s_master.private_ip}"
}

output "k3s_kubeconfig_command" {
  description = "Command to get kubeconfig"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.k3s_master.private_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml'"
}
