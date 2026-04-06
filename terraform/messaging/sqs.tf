resource "aws_sqs_queue" "travel_platform_upload_queue" {
  name                       = "travel_platform_upload_queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400 # 1 day

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.travel_platform_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name    = "travel_platform_upload_queue"
    Project = "travel-platform"
    Env     = "dev"
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "travel_platform_dlq" {
  name                      = "travel_platform_dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name    = "travel_platform_dlq"
    Project = "travel-platform"
    Env     = "dev"
  }
}