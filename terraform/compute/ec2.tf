# Bastion Host(Public Subnet)
resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.amazon_linux.image_id
  instance_type = "t3.micro"

  subnet_id = var.public_subnet_id

  vpc_security_group_ids = [var.bastion_sg_id]

  associate_public_ip_address = true

  key_name = var.key_name

  tags = {
    Name        = "travel_platform_bastion_host"
    Project     = "travel_platform"
    Role        = "bastion"
    Environment = "dev"
    Access      = "ssh"
  }
}

#Private EC2 - App Server
resource "aws_instance" "app_server" {
  #AMI with Docker pre-installed
  ami           = data.aws_ami.custom_ami.id
  instance_type = "t3.micro"

  subnet_id = var.private_subnet_id

  vpc_security_group_ids = [var.app_sg_id]

  associate_public_ip_address = false

  key_name = var.key_name

  iam_instance_profile = var.instance_profile_name

  user_data = templatefile("${path.module}/user_data.sh", {
    sqs_queue_url = var.sqs_queue_url
    db_endpoint   = var.db_endpoint
    db_password   = var.db_password
  })

  tags = {
    Name        = "travel_platform_app_server"
    Project     = "travel_platform"
    Role        = "app"
    Environment = "dev"
  }
}