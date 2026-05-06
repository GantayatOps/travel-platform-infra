output "sqs_queue_url" {
  value = aws_sqs_queue.travel_platform_upload_queue.id
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.travel_platform_upload_queue.arn
}

output "sqs_dlq_name" {
  value = aws_sqs_queue.travel_platform_dlq.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.travel_platform_upload_topic.arn
}
