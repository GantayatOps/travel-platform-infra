# Bastion host security group
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
    Name = "travel-platform-bastion-sg"
  }
}

# Application security group
resource "aws_security_group" "travel_platform_app_sg" {
  name   = "app-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow SSH only from the bastion security group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.travel_platform_bastion_sg.id]
  }

  ingress {
    description = "Allow app port from inside the VPC"
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
    Name = "travel-platform-app-sg"
  }
}

# RDS security group
resource "aws_security_group" "travel_platform_rds_sg" {
  name   = "rds-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL from app and Lambda security groups"
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
    Name = "travel-platform-rds-sg"
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "travel_platform_lambda_sg"
  description = "Lambda SG"
  vpc_id      = var.vpc_id

  # Lambda initiates outbound connections only.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "travel-platform-lambda-sg"
  }
}
