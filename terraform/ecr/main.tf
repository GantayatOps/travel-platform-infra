resource "aws_ecr_repository" "app_repo" {
  name                 = "travel-app-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

#   encryption_configuration {
#     encryption_type = "AES256"
#   }

  tags = {
    Name = "travel-app-ecr"
  }
}