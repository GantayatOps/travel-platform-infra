# Instance profiles to attach IAM role to EC2
resource "aws_iam_instance_profile" "travel_platform_ec2_instance_profile" {
  name = "travel_platform_ec2_instance_profile"
  role = aws_iam_role.travel_platform_ec2_role.name
}