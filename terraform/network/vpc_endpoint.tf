# Access S3 via S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.travel_platform_vpc.id
  service_name      = "com.amazonaws.ap-south-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_rt.id
  ]
}