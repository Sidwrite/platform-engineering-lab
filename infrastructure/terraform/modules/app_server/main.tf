# Application Server Module for Knova Fintech

# Application Server EC2 Instance
resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = "t3.micro" # Free tier eligible
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name != "" ? var.key_name : null

  # User data script for application setup
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
    db_endpoint = var.db_endpoint
  }))

  # EBS optimization
  ebs_optimized = true

  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.environment}-pet-app-root"
    }
  }

  # Additional EBS volume removed for 100% Free Tier compliance
  # ebs_block_device {
  #   device_name = "/dev/sdf"
  #   volume_type = "gp3"
  #   volume_size = 10
  #   encrypted   = true
  #   tags = {
  #     Name = "${var.environment}-pet-app-data"
  #   }
  # }

  tags = {
    Name = "${var.environment}-pet-app-server"
    Type = "Application"
  }
}

# Note: Application Load Balancer removed to stay within AWS Free Tier
# For production, you would add ALB for high availability
