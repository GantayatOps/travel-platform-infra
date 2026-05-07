output "bastion_sg_id" {
  description = "ID of the bastion host security group."
  value       = aws_security_group.travel_platform_bastion_sg.id
}

output "app_sg_id" {
  description = "ID of the application EC2 security group."
  value       = aws_security_group.travel_platform_app_sg.id
}

output "rds_sg_id" {
  description = "ID of the RDS PostgreSQL security group."
  value       = aws_security_group.travel_platform_rds_sg.id
}

output "lambda_sg_id" {
  description = "ID of the Lambda security group."
  value       = aws_security_group.lambda_sg.id
}

output "ec2_instance_profile_name" {
  description = "Name of the IAM instance profile attached to EC2 instances."
  value       = aws_iam_instance_profile.travel_platform_ec2_instance_profile.name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role assumed by the upload-processing Lambda."
  value       = aws_iam_role.travel_platform_lambda_role.arn
}
