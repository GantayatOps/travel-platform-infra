output "bastion_public_ip" {
  value = module.compute_layer.bastion_public_ip
}

output "app_private_ip" {
  value = module.compute_layer.app_private_ip
}

output "db_endpoint" {
  value = module.database_layer.db_endpoint
}

output "sqs_queue_url" {
  description = "SQS Queue URL for application"
  value       = module.messaging_layer.sqs_queue_url
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for application"
  value       = module.messaging_layer.sns_topic_arn
}