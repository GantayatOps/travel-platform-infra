output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.travel_platform_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet_1.id
}

output "private_subnet_id_2" {
  value = aws_subnet.private_subnet_2.id
}

output "ecr_api_endpoint_id" {
  value = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  value = aws_vpc_endpoint.ecr_dkr.id
}