variable "private_subnet_ids" {
  description = "Private subnet IDs used by the RDS subnet group."
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security group ID attached to the RDS PostgreSQL instance."
  type        = string
}
