variable "vpc_id" {
  description = "ID of the VPC where security groups are created."
  type        = string
}

variable "resource_arns" {
  description = "AWS resource ARNs used by IAM policies in the security layer."
  type = object({
    bucket    = string
    sqs_queue = string
    sns_topic = string
    db_secret = string
  })
}
