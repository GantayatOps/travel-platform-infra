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