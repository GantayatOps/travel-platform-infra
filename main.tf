provider "aws" {
  region = "ap-south-2"
}

module "network_layer" {
  source = "./terraform/network"
}