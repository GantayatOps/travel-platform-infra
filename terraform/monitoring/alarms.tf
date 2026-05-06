locals {
  common_tags = {
    Project = "travel-platform"
    Env     = "dev"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "travel-platform-lambda-errors"
  alarm_description   = "Lambda upload processor has one or more errors."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "sqs_dlq_visible_messages" {
  alarm_name          = "travel-platform-sqs-dlq-visible-messages"
  alarm_description   = "SQS dead-letter queue has messages that need investigation."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    QueueName = var.sqs_dlq_name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "app_instance_status_check" {
  alarm_name          = "travel-platform-app-instance-status-check"
  alarm_description   = "Private app EC2 instance failed an AWS status check."
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    InstanceId = var.app_instance_id
  }

  tags = local.common_tags
}
