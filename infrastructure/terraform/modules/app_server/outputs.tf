# App Server Module Outputs

output "app_instance_id" {
  description = "ID of the application instance"
  value       = aws_instance.app.id
}

output "app_private_ip" {
  description = "Private IP of the application server"
  value       = aws_instance.app.private_ip
}

# ALB outputs removed - not using ALB in free tier
