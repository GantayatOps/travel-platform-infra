provider "aws" {
  region = var.aws_region
}

module "network_layer" {
  source = "./terraform/network"
}

module "security_layer" {
  source = "./terraform/security"
  
  # From Network Layer
  vpc_id = module.network_layer.vpc_id

  # From Storage Layer
  bucket_arn = module.storage_layer.bucket_arn

  # From Messaging Layer
  sqs_queue_arn = module.messaging_layer.sqs_queue_arn
  sns_topic_arn = module.messaging_layer.sns_topic_arn
}

module "compute_layer" {
  source = "./terraform/compute"

  # From network layer
  public_subnet_id  = module.network_layer.public_subnet_id
  private_subnet_id = module.network_layer.private_subnet_id

  # From security layer
  bastion_sg_id = module.security_layer.bastion_sg_id
  app_sg_id     = module.security_layer.app_sg_id
  instance_profile_name = module.security_layer.ec2_instance_profile_name

  # Key-Value Pair stored in AWS
  key_name = var.key_name

  #From messaging layer
  sqs_queue_url = module.messaging_layer.sqs_queue_url

  db_endpoint = split(":", module.database_layer.db_endpoint)[0]
  db_password = var.db_password

}
module "database_layer" {
  source = "./terraform/database"

  # From Network layer
  private_subnet_ids = [
    module.network_layer.private_subnet_id,
    module.network_layer.private_subnet_id_2
  ]
  # From security layer
  rds_sg_id = module.security_layer.rds_sg_id
  
  db_password = var.db_password
}

module "storage_layer" {
  source = "./terraform/storage"

  bucket_name = var.bucket_name

  # From messaging layer
  sqs_queue_arn = module.messaging_layer.sqs_queue_arn
}

module "messaging_layer" {
  source = "./terraform/messaging"

  notification_email = var.notification_email
  bucket_arn = module.storage_layer.bucket_arn
}

module "lambda_layer" {
  source = "./terraform/compute/lambda"

  # From tfvars
  db_password = var.db_password
  enable_lambda_trigger = var.enable_lambda_trigger

  # From messaging layer
  sqs_queue_arn = module.messaging_layer.sqs_queue_arn
  sns_topic_arn = module.messaging_layer.sns_topic_arn

  # From Security
  lambda_role_arn = module.security_layer.lambda_role_arn
  lambda_sg_id = module.security_layer.lambda_sg_id

  # From Network layer
  private_subnet_ids = [
    module.network_layer.private_subnet_id,
    module.network_layer.private_subnet_id_2
  ]
  
  # From Database layer
  db_host = module.database_layer.db_host
}