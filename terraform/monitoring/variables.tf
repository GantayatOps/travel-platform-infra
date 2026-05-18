variable "alarm_targets" {
  description = "Resource identifiers used by CloudWatch alarm dimensions."
  type = object({
    lambda_function_name = string
    sqs_dlq_name         = string
    app_instance_id      = string
  })
}

variable "alarm_actions" {
  description = "SNS topic ARNs or other action ARNs to notify when alarms fire"
  type        = list(string)
  default     = []
}
