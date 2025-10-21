# Bastion Host Module for Knova Fintech

# Key Pair (if not exists)
resource "aws_key_pair" "main" {
  count      = var.key_name != "" ? 1 : 0
  key_name   = var.key_name
  public_key = var.public_key != "" ? var.public_key : file("~/.ssh/id_rsa.pub")
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = "t3.micro" # Free tier eligible
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name != "" ? var.key_name : null

  # User data script for basic setup
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  }))

  # EBS optimization
  ebs_optimized = true

  # Root volume
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.environment}-pet-bastion-root"
    }
  }

  tags = {
    Name = "${var.environment}-pet-bastion"
    Type = "Bastion"
  }
}

# Elastic IP for Bastion
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "${var.environment}-pet-bastion-eip"
  }
}
