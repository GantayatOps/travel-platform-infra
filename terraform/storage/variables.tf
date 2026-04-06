variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "sqs_queue_arn" {
  type = string
}