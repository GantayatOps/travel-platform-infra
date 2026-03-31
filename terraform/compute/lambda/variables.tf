variable "sqs_queue_arn" {
  description = "ARN of the SQS queue used as an event source for the Lambda function"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic where Lambda publishes processed messages"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM role ARN assumed by the Lambda function to access AWS services like SQS, SNS, and CloudWatch"
  type        = string
}