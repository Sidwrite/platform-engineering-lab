# Database Module for Knova Fintech - PostgreSQL RDS

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-pet-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.environment}-pet-db-subnet-group"
  }
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-pet-postgres"

  # Engine configuration
  engine         = "postgres"
  engine_version = "15.14"
  instance_class = var.db_instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Deletion protection
  deletion_protection = false # Set to true in production
  skip_final_snapshot = true  # Set to false in production

  tags = {
    Name = "${var.environment}-pet-postgres"
  }
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.environment}-pet-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-pet-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
