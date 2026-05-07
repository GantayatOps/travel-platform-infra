# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-2a"

  map_public_ip_on_launch = true

  tags = {
    Name = "travel-platform-public-subnet"
  }
}

# Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-2a"

  map_public_ip_on_launch = false

  tags = {
    Name = "travel-platform-private-subnet-1"
  }
}

# Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-south-2b"

  map_public_ip_on_launch = false

  tags = {
    Name = "travel-platform-private-subnet-2"
  }
}
