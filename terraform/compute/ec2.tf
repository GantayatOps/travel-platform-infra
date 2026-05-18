# Bastion host in the public subnet
resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.amazon_linux.image_id
  instance_type = "t3.micro"

  subnet_id = var.network_config.public_subnet_id

  vpc_security_group_ids = [var.security_config.bastion_sg_id]

  associate_public_ip_address = true

  key_name = var.runtime_config.key_name

  tags = {
    Name   = "travel-platform-bastion-host"
    Role   = "bastion"
    Access = "ssh"
  }
}

# Private application EC2 instance
resource "aws_instance" "app_server" {
  # Custom AMI includes Docker for container-based deploys.
  ami           = data.aws_ami.custom_ami.id
  instance_type = "t3.micro"

  subnet_id = var.network_config.private_subnet_id

  vpc_security_group_ids = [var.security_config.app_sg_id]

  associate_public_ip_address = false

  key_name = var.runtime_config.key_name

  iam_instance_profile = var.security_config.instance_profile_name

  user_data = templatefile("${path.module}/user_data.sh", {
    sqs_queue_url = var.runtime_config.sqs_queue_url
    db_endpoint   = var.runtime_config.db_endpoint
    db_secret_arn = var.runtime_config.db_secret_arn
  })

  tags = {
    Name = "travel-platform-app-server"
    Role = "app"
  }
}
