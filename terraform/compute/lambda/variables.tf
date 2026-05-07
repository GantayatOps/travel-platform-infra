variable "enable_lambda_trigger" {
  description = "Whether to enable the SQS event source mapping for the Lambda function."
  type        = bool
  default     = false
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue used as an event source for the Lambda function."
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic where Lambda publishes processed upload notifications."
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name expected in upload events."
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM role ARN assumed by the Lambda function."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where the Lambda function runs."
  type        = list(string)
}

variable "lambda_sg_id" {
  description = "Security group ID attached to the Lambda function."
  type        = string
}

variable "db_host" {
  description = "RDS PostgreSQL hostname used by Lambda."
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN containing database credentials."
  type        = string
}
