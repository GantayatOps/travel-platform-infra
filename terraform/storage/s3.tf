# S3 Bucket
resource "aws_s3_bucket" "app_bucket" {
  bucket = "travel-platform-assets-952341"

  tags = {
    Name = "App Storage"
  }
}