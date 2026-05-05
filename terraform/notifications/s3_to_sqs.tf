resource "aws_s3_bucket_notification" "s3_to_sqs" {
  bucket = var.bucket_id

  queue {
    queue_arn = var.sqs_queue_arn
    events    = ["s3:ObjectCreated:*"]
  }
}
