resource "aws_sqs_queue" "travel_platform_upload_queue" {
  name                       = "travel_platform_upload_queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400 # 1 day

  tags = {
    Name    = "travel_platform_upload_queue"
    Project = "travel-platform"
    Env     = "dev"
  }
}