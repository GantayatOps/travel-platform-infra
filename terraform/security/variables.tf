variable "vpc_id" {
  description = "VPC ID for SG"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of S3 bucket used by application"
  type        = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}