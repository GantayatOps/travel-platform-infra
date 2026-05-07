variable "bucket_id" {
  description = "ID/name of the S3 bucket that emits upload-created notifications."
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue that receives S3 upload notifications."
  type        = string
}
