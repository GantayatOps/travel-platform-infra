variable "notification_email" {
  description = "Email address subscribed to the SNS topic for alerts and upload notifications."
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket allowed to send upload events to SQS."
  type        = string
}
