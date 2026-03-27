resource "aws_sns_topic" "travel_platform_upload_topic" {
  name = "travel_platform_upload_topic"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.travel_platform_upload_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email
}