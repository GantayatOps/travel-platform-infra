# IAM Role for EC2 to access S3
resource "aws_iam_role" "travel_platform_ec2_role" {
  name = "travel_platform_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
  Project = "travel-platform"
  Env     = "dev"
}
}