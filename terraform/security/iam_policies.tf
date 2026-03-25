# S3 access permissions
resource "aws_iam_policy" "s3_policy" {
  name = "ec2_s3_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Object-level permissions
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${var.bucket_arn}/*"
      },
      {
        # Bucket-level permission
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = var.bucket_arn
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}