provider "aws" {
  region = "ap-south-2"
}

module "network_layer" {
  source = "./terraform/network"
}

module "security_layer" {
  source = "./terraform/security"
}