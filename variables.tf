variable "aws_region" {
  description = "AWS region where the main travel platform infrastructure is deployed."
  type        = string
}

variable "environment" {
  description = "Deployment environment name used for tagging and environment-specific defaults."
  type        = string
  default     = "dev"
}

variable "key_name" {
  description = "Existing EC2 key pair name used for bastion and app server SSH access."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name used for travel photo assets."
  type        = string
}

variable "notification_email" {
  description = "Email address subscribed to the SNS topic for alerts and upload notifications."
  type        = string
}

variable "enable_lambda_trigger" {
  description = "Whether to enable the SQS event source mapping for the upload-processing Lambda."
  type        = bool
  default     = false
}

variable "instance_types" {
  description = "EC2 instance type by environment, with a safe fallback applied in locals."
  type        = map(string)
  default = {
    dev = "t3.micro"
  }
}
