resource "aws_iam_instance_profile" "profile" {
  name = "ec2_s3_profile"
  role = aws_iam_role.ec2_s3_role.name
}