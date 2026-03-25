# Instance profiles to attach IAM role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_app_instance_profile"
  role = aws_iam_role.ec2_app_role.name
}