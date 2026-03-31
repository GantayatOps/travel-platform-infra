variable "public_subnet_id" {
  description = "Public subnet ID where the bastion EC2 instance will be launched"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID where the application EC2 instance will be launched"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security Group ID attached to the bastion host for SSH access"
  type        = string
}

variable "app_sg_id" {
  description = "Security Group ID attached to the application EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 key pair used for SSH access"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name attached to EC2 instances for AWS service access"
  type        = string
}

variable "sqs_queue_url" {
  description = "SQS queue URL used by the application to send messages for asynchronous processing"
  type        = string
}