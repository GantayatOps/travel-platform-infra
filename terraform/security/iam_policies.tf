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
    Name = "travel-platform-s3-access-policy"
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
    Name = "travel-platform-ecr-pull-policy"
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
      },
      {
        Sid    = "AllowSQSConsumeMessage"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [var.sqs_queue_arn]
      }
    ]
  })

  tags = {
    Name = "travel-platform-messaging-policy"
  }
}

# Attach SQS policy to EC2 role
resource "aws_iam_role_policy_attachment" "sqs_sns_attach" {
  role       = aws_iam_role.travel_platform_ec2_role.name
  policy_arn = aws_iam_policy.travel_platform_messaging_policy.arn
}

resource "aws_iam_policy" "travel_platform_db_secret_access_policy" {
  count = var.db_secret_arn != null ? 1 : 0

  name = "travel_platform_db_secret_access_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.db_secret_arn
      }
    ]
  })

  tags = {
    Name = "travel-platform-db-secret-access-policy"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_db_secret_attach" {
  count = var.db_secret_arn != null ? 1 : 0

  role       = aws_iam_role.travel_platform_ec2_role.name
  policy_arn = aws_iam_policy.travel_platform_db_secret_access_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_access" {
  role       = aws_iam_role.travel_platform_lambda_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.travel_platform_lambda_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Inline Policy, Maybe later change to Policy + Attachment?
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_sqs_sns_policy"
  role = aws_iam_role.travel_platform_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
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
          "s3:GetObject"
        ]
        Resource = "${var.bucket_arn}/*"
      }
      ], var.db_secret_arn != null ? [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.db_secret_arn
      }
      ] : [], [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ])
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
    Name = "travel-platform-ecr-push-policy"
  }
}

resource "aws_iam_role_policy_attachment" "github_ecr_attach" {
  role       = aws_iam_role.travel_platform_github_role.name
  policy_arn = aws_iam_policy.travel_platform_ecr_push_policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.travel_platform_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "travel_platform_ssm_send_command" {
  name        = "travel_platform_ssm_send_command"
  description = "Allow GitHub Actions to trigger SSM Run Command"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "travel-platform-ssm-send-command-policy"
  }
}

resource "aws_iam_role_policy_attachment" "github_ssm_attach" {
  role       = aws_iam_role.travel_platform_github_role.name
  policy_arn = aws_iam_policy.travel_platform_ssm_send_command.arn
}
