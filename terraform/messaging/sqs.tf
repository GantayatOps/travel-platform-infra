resource "aws_sqs_queue" "travel_platform_upload_queue" {
  name                       = "travel_platform_upload_queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400 # 1 day

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.travel_platform_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "travel-platform-upload-queue"
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "travel_platform_dlq" {
  name                      = "travel_platform_dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name = "travel-platform-dlq"
  }
}

resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.travel_platform_upload_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "s3-send-message"
    Statement = [
      {
        Sid    = "AllowS3SendMessage"
        Effect = "Allow"

        Principal = {
          Service = "s3.amazonaws.com"
        }

        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.travel_platform_upload_queue.arn

        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.bucket_arn
          }
        }
      }
    ]
  })
}
