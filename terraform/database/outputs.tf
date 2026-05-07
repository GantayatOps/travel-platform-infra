output "db_endpoint" {
  description = "RDS PostgreSQL endpoint, including port."
  value       = aws_db_instance.postgres_db.endpoint
}

output "db_host" {
  description = "RDS PostgreSQL hostname without the port."
  value       = aws_db_instance.postgres_db.address
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for the RDS-managed master user password."
  value       = try(aws_db_instance.postgres_db.master_user_secret[0].secret_arn, null)
}
