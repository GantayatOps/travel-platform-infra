output "sqs_queue_url" {
  description = "URL of the primary upload-processing SQS queue."
  value       = aws_sqs_queue.travel_platform_upload_queue.id
}

output "sqs_queue_arn" {
  description = "ARN of the primary upload-processing SQS queue."
  value       = aws_sqs_queue.travel_platform_upload_queue.arn
}

output "sqs_dlq_name" {
  description = "Name of the upload-processing dead-letter queue."
  value       = aws_sqs_queue.travel_platform_dlq.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for notifications and alarm actions."
  value       = aws_sns_topic.travel_platform_upload_topic.arn
}
