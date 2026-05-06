output "app_repository_name" {
  description = "ECR repository used by CI/CD for the Flask app image"
  value       = aws_ecr_repository.app_repo.name
}

output "app_repository_url" {
  description = "Full ECR repository URL used by GitHub Actions and EC2 deploy scripts"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "worker_repository_name" {
  description = "Retained legacy ECR repository for historical worker images"
  value       = aws_ecr_repository.worker_repo.name
}

output "worker_repository_url" {
  description = "Full ECR repository URL for the retained legacy worker repository"
  value       = aws_ecr_repository.worker_repo.repository_url
}
