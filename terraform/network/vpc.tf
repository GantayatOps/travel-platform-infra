resource "aws_vpc" "travel_platform_vpc" {
  cidr_block = "10.0.0.0/16"

  # REQUIRED for VPC endpoints
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "travel-platform-vpc"
    Environment = "learning"
  }
}