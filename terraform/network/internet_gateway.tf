resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.travel_platform_vpc.id

  tags = {
    Name = "travel-platform-igw"
  }
}