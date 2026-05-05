variable "private_subnet_ids" {
  type = list(string)
}

variable "rds_sg_id" {
  description = "RDS SG ID"
  type        = string
}
