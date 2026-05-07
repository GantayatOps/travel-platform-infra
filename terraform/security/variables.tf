variable "vpc_id" {
  description = "ID of the VPC where security groups are created."
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket used by the application."
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue used by EC2 and Lambda."
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic used by Lambda and CloudWatch alarms."
  type        = string
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for the RDS-managed master user password."
  type        = string
}
