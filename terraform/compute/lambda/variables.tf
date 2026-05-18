variable "event_source_config" {
  description = "SQS event source mapping settings for the Lambda processor."
  type = object({
    enabled       = bool
    sqs_queue_arn = string
  })
}

variable "network_config" {
  description = "Private subnet and security group placement for the Lambda function."
  type = object({
    private_subnet_ids = list(string)
    security_group_id  = string
  })
}

variable "runtime_config" {
  description = "IAM, notification, storage, and database settings passed to the Lambda runtime."
  type = object({
    role_arn      = string
    sns_topic_arn = string
    bucket_name   = string
    db_host       = string
    db_secret_arn = string
  })
}
