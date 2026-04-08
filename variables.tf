variable "aws_region" {
  type = string
}

variable "key_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "notification_email" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "enable_lambda_trigger" {
  type    = bool
  default = false
}