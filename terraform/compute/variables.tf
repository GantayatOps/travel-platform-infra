variable "network_config" {
  description = "Subnet placement for the bastion and private application EC2 instances."
  type = object({
    public_subnet_id  = string
    private_subnet_id = string
  })
}

variable "security_config" {
  description = "Security groups and IAM instance profile attached to EC2 instances."
  type = object({
    bastion_sg_id         = string
    app_sg_id             = string
    instance_profile_name = string
  })
}

variable "runtime_config" {
  description = "Runtime configuration passed to EC2 instances and deployment user data."
  type = object({
    key_name      = string
    instance_type = string
    sqs_queue_url = string
    db_endpoint   = string
    db_secret_arn = string
  })
}
