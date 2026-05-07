output "bastion_public_ip" {
  description = "Public IPv4 address of the bastion host."
  value       = aws_instance.bastion_host.public_ip
}

output "app_private_ip" {
  description = "Private IPv4 address of the application EC2 instance."
  value       = aws_instance.app_server.private_ip
}

output "app_instance_id" {
  description = "Instance ID of the private application EC2 instance."
  value       = aws_instance.app_server.id
}
