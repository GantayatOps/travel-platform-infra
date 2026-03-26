variable "public_subnet_id" {
  description = "Public Subnet ID where EC2 will be launched"
  type        = string
}

variable "private_subnet_id" {
  description = "Private Subnet ID where EC2 will be launched"
  type        = string
}

variable "bastion_sg_id" {
  description = "Bastion SG ID"
  type        = string
}

variable "app_sg_id" {
  description = "App SG ID"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "instance_profile_name" {
  type = string
}

# Custom AMI for app server (Docker pre-installed)
variable "app_ami_id" {
  description = "AMI ID for app server"
  type        = string
}