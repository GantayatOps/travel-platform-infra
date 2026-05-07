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
    Name = "travel-platform-ec2-role"
  }
}

# IAM Role for lambda function to access SQS/SNS/CW
resource "aws_iam_role" "travel_platform_lambda_role" {
  name = "travel_platform_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "travel-platform-lambda-role"
  }
}

resource "aws_iam_role" "travel_platform_github_role" {
  name = "travel_platform_github_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:GantayatOps/travel-platform-infra:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name = "travel-platform-github-role"
  }
}
