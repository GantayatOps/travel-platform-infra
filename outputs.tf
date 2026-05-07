output "bastion_public_ip" {
  description = "Public IPv4 address of the bastion host."
  value       = module.compute_layer.bastion_public_ip
}

output "app_private_ip" {
  description = "Private IPv4 address of the application EC2 instance."
  value       = module.compute_layer.app_private_ip
}

output "db_endpoint" {
  description = "RDS PostgreSQL endpoint, including port."
  value       = module.database_layer.db_endpoint
}

output "sqs_queue_url" {
  description = "SQS queue URL used by the application upload flow."
  value       = module.messaging_layer.sqs_queue_url
}

output "sns_topic_arn" {
  description = "SNS topic ARN used for upload notifications and CloudWatch alarm actions."
  value       = module.messaging_layer.sns_topic_arn
}
