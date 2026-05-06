variable "lambda_function_name" {
  description = "Name of the Lambda function that processes SQS upload events"
  type        = string
}

variable "sqs_dlq_name" {
  description = "Name of the SQS dead-letter queue for failed upload events"
  type        = string
}

variable "app_instance_id" {
  description = "Instance ID of the private EC2 app server"
  type        = string
}

variable "alarm_actions" {
  description = "SNS topic ARNs or other action ARNs to notify when alarms fire"
  type        = list(string)
  default     = []
}
