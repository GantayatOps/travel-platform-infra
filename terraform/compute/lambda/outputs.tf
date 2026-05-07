output "lambda_function_name" {
  description = "Name of the upload-processing Lambda function."
  value       = aws_lambda_function.travel_platform_sqs_processor.function_name
}
