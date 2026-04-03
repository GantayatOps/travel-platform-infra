# Access S3 via S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  service_name      = "com.amazonaws.ap-south-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_rt.id
  ]
}

# Security group for VPC Endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name   = "vpc-endpoint-sg"
  vpc_id = aws_vpc.travel_platform_vpc.id

  ingress {
    description = "Allow HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECR API Endpoint (Authentication)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  service_name      = "com.amazonaws.ap-south-2.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true
}

# ECR DKR Endpoint (Docker Pull)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  service_name      = "com.amazonaws.ap-south-2.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true
}

# SQS Endpoint (Messaging Queue)
resource "aws_vpc_endpoint" "sqs" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  service_name      = "com.amazonaws.ap-south-2.sqs"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true
}

# SNS Endpoint (Notifications)
resource "aws_vpc_endpoint" "sns" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  service_name      = "com.amazonaws.ap-south-2.sns"
  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  service_name      = "com.amazonaws.ap-south-2.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  service_name      = "com.amazonaws.ap-south-2.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  service_name      = "com.amazonaws.ap-south-2.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  private_dns_enabled = true
}