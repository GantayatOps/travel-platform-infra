output "bastion_sg_id" {
  value = aws_security_group.travel_platform_bastion_sg.id
}

output "app_sg_id" {
  value = aws_security_group.travel_platform_app_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.travel_platform_rds_sg.id
}

output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}

output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.travel_platform_ec2_instance_profile.name
}

output "lambda_role_arn" {
  value = aws_iam_role.travel_platform_lambda_role.arn
}