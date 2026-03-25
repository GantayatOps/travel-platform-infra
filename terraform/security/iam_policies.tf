# S3 access permissions
resource "aws_iam_policy" "s3_policy" {
  name = "ec2_s3_policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "${var.bucket_arn}/*"
      },
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}