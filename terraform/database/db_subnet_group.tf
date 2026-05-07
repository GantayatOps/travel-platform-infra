resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "travel-platform-db-subnet"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "travel-platform-db-subnet-group"
  }
}
