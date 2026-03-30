variable "sqs_queue_arn" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "lambda_role_arn" {
  description = "IAM Role ARN for Lambda"
  type        = string
}
