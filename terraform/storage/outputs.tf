output "bucket_arn" {
  description = "ARN of the S3 bucket used for travel photo assets."
  value       = aws_s3_bucket.app_bucket.arn
}

output "bucket_id" {
  description = "ID/name of the S3 bucket used for travel photo assets."
  value       = aws_s3_bucket.app_bucket.id
}
