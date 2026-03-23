resource "aws_vpc" "travel_platform_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "travel-platform-vpc"
    Environment = "learning"
  }
}