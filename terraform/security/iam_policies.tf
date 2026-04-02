# Allows EC2 to upload and retrieve objects from S3 bucket
resource "aws_iam_policy" "travel_platform_s3_access_policy" {
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

# Attach S3 policy to EC2 role
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.travel_platform_ec2_role.name
  policy_arn = aws_iam_policy.travel_platform_s3_access_policy.arn
}

# Allows EC2 to access ECR
resource "aws_iam_policy" "travel_platform_ecr_pull_policy" {
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

# Attach ECR policy to EC2 role
resource "aws_iam_role_policy_attachment" "ecr_attach" {
  role       = aws_iam_role.travel_platform_ec2_role.name
  policy_arn = aws_iam_policy.travel_platform_ecr_pull_policy.arn
}

# Allows EC2 to access SQS
resource "aws_iam_policy" "travel_platform_messaging_policy" {
  name = "travel_platform_messaging_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSQSSendMessage"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = [var.sqs_queue_arn]
      }
    ]
  })

  tags = {
    Project = "travel-platform"
    Env     = "dev"
  }
}

# Attach SQS policy to EC2 role
resource "aws_iam_role_policy_attachment" "sqs_sns_attach" {
  role       = aws_iam_role.travel_platform_ec2_role.name
  policy_arn = aws_iam_policy.travel_platform_messaging_policy.arn
}

# Inline Policy, Maybe later change to Policy + Attachment?
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_sqs_sns_policy"
  role = aws_iam_role.travel_platform_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "travel_platform_ecr_push_policy" {
  name = "travel_platform_ecr_push_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage"
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

resource "aws_iam_role_policy_attachment" "github_ecr_attach" {
  role       = aws_iam_role.travel_platform_github_role.name
  policy_arn = aws_iam_policy.travel_platform_ecr_push_policy.arn
}