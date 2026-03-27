# Allows EC2 to upload and retrieve objects from S3 bucket
resource "aws_iam_policy" "s3_policy" {
  name = "travel_platform_s3_access_policy"

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

  tags = {
  Project = "travel-platform"
  Env     = "dev"
}
}

# IAM Policy which defines what EC2 can do with ECR
resource "aws_iam_policy" "ecr_policy" {
  name = "travel_platform_ecr_pull_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Allows fetching auth token
          "ecr:GetAuthorizationToken",

          # Allows pulling image metadata
          "ecr:BatchGetImage",

          # Allows downloading image layers
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
  Project = "travel-platform"
  Env     = "dev"
}
}

# Attach S3 policy to role
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

# Attach ECR policy to role
resource "aws_iam_role_policy_attachment" "ecr_attach" {
  role       = aws_iam_role.ec2_app_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}
