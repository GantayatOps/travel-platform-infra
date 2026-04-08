# Bastion Host SG
resource "aws_security_group" "travel_platform_bastion_sg" {
  name   = "bastion-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "travel-platform-bastion-sg"
    Project = "travel-platform"
    Env     = "dev"
  }
}

# App SG
resource "aws_security_group" "travel_platform_app_sg" {
  name   = "app-sg"
  vpc_id = var.vpc_id

  # Allow SSH ONLY from bastion_sg
  ingress {
    description     = "Allow SSH only from Bastion SG"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.travel_platform_bastion_sg.id]
  }

  # SG for port 3000
  ingress {
    description = "App port from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "travel-platform-app-sg"
    Project = "travel-platform"
    Env     = "dev"
  }
}

# RDS SG
resource "aws_security_group" "travel_platform_rds_sg" {
  name   = "rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL from app and lambda SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.travel_platform_app_sg.id, aws_security_group.lambda_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "travel-platform-rds-sg"
    Project = "travel-platform"
    Env     = "dev"
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "travel_platform_lambda_sg"
  description = "Lambda SG"
  vpc_id      = var.vpc_id

  # No ingress needed

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "travel-platform-lambda-sg"
    Project = "travel-platform"
    Env     = "dev"
  }
}