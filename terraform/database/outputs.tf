output "db_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}

output "db_host" {
  value = aws_db_instance.postgres_db.address
}

output "db_secret_arn" {
  value = aws_db_instance.postgres_db.master_user_secret[0].secret_arn
}
