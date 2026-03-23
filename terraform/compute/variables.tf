variable "public_subnet_id" {
  description = "Subnet where EC2 will be launched"
  type        = string
}

variable "bastion_sg_id" {
  description = "Bastion SG ID"
  type        = string
}