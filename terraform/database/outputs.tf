output "db_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}

output "db_host" {
  value = aws_db_instance.postgres_db.address
}