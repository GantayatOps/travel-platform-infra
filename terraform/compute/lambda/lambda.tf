resource "aws_lambda_function" "travel_platform_sqs_processor" {
  function_name = "travel_platform_sqs_processor"

  vpc_config {
    subnet_ids         = var.network_config.private_subnet_ids
    security_group_ids = [var.network_config.security_group_id]
  }

  role    = var.runtime_config.role_arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.10"

  architectures = ["arm64"]

  # The zip is built by scripts/package_lambda.sh and checked in so Terraform can run from clean CI workspaces.
  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  timeout = 10

  tags = {
    Name = "travel-platform-sqs-processor"
  }

  environment {
    variables = {
      SNS_TOPIC_ARN = var.runtime_config.sns_topic_arn
      BUCKET_NAME   = var.runtime_config.bucket_name
      DB_HOST       = var.runtime_config.db_host
      DB_NAME       = "appdb"
      DB_USER       = "postgres"
      DB_SECRET_ARN = var.runtime_config.db_secret_arn
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  count = var.event_source_config.enabled ? 1 : 0

  event_source_arn = var.event_source_config.sqs_queue_arn
  function_name    = aws_lambda_function.travel_platform_sqs_processor.arn
  batch_size       = 1
}
