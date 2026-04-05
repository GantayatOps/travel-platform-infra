# S3 Bucket
resource "aws_s3_bucket" "app_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "App Storage"
  }
}