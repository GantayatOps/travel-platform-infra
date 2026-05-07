output "vpc_id" {
  description = "ID of the travel platform VPC."
  value       = aws_vpc.travel_platform_vpc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet used by the bastion host."
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "ID of the first private subnet used by the app, Lambda, and RDS."
  value       = aws_subnet.private_subnet_1.id
}

output "private_subnet_id_2" {
  description = "ID of the second private subnet used for multi-AZ RDS and Lambda networking."
  value       = aws_subnet.private_subnet_2.id
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API VPC endpoint."
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR Docker registry VPC endpoint."
  value       = aws_vpc_endpoint.ecr_dkr.id
}
