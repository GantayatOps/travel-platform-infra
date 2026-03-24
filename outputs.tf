output "bastion_public_ip" {
  value = module.compute_layer.bastion_public_ip
}

output "app_private_ip" {
  value = module.compute_layer.app_private_ip
}