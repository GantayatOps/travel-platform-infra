provider "aws" {
  region = "ap-south-2"
}

module "network_layer" {
  source = "./terraform/network"
}

module "security_layer" {
  source = "./terraform/security"

  vpc_id = module.network_layer.vpc_id
}

module "compute_layer" {
  source = "./terraform/compute"

  public_subnet_id = module.network_layer.public_subnet_id
  bastion_sg_id = module.security_layer.bastion_sg_id
}