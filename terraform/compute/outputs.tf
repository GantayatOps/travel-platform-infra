output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = aws_instance.bastion_host.public_ip
}

output "app_private_ip" {
  description = "Private IP of app server"
  value       = aws_instance.app_server.private_ip
}