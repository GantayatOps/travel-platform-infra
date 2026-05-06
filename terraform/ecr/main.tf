# App ECR Repository
resource "aws_ecr_repository" "app_repo" {
  name                 = "travel-app-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "travel-app-ecr"
  }
}

# Keep last 5 images only
resource "aws_ecr_lifecycle_policy" "keep_last_5" {
  repository = aws_ecr_repository.app_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
