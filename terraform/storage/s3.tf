# S3 Bucket
resource "aws_s3_bucket" "app_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "App Storage"
  }
}

resource "aws_s3_bucket_notification" "s3_to_sqs" {
  bucket = aws_s3_bucket.app_bucket.id

  queue {
    queue_arn = var.sqs_queue_arn
    events    = ["s3:ObjectCreated:*"]
  }
}