resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "main"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "rds-subnet-group"
  }
}