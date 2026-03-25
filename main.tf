provider "aws" {
  region = "ap-south-2"
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
}


module "compute_layer" {
  source = "./terraform/compute"

  # From network layer
  public_subnet_id  = module.network_layer.public_subnet_id
  private_subnet_id = module.network_layer.private_subnet_id

  # From security layer
  bastion_sg_id = module.security_layer.bastion_sg_id
  app_sg_id     = module.security_layer.app_sg_id
  instance_profile_name = module.security_layer.instance_profile_name

 # Key-Value Pair stored in AWS
  key_name = "travel-platform-key"
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
}

module "storage_layer" {
  source = "./terraform/storage"
}