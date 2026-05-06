resource "aws_lambda_function" "travel_platform_sqs_processor" {
  function_name = "travel_platform_sqs_processor"

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  role    = var.lambda_role_arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.10"

  architectures = ["arm64"]

  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  timeout = 10

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
      BUCKET_NAME   = var.bucket_name
      DB_HOST       = var.db_host
      DB_NAME       = "appdb"
      DB_USER       = "postgres"
      DB_SECRET_ARN = var.db_secret_arn
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  count = var.enable_lambda_trigger ? 1 : 0

  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.travel_platform_sqs_processor.arn
  batch_size       = 1
}
