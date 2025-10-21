# Security Groups Module Outputs

output "bastion_sg_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "app_sg_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "database_sg_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}
