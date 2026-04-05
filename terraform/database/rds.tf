# RDS Instance
resource "aws_db_instance" "postgres_db" {
  identifier = "travel-platform-db"

  engine         = "postgres"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  db_name           = "appdb"
  username          = "postgres"
  password          = var.db_password

  publicly_accessible = false

  vpc_security_group_ids = [var.rds_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  skip_final_snapshot = true
}