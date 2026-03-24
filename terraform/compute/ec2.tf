data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion Host(Public Subnet)
resource "aws_instance" "bastion_host" {
  #Fix Hardcoded AMI
  ami           = data.aws_ami.amazon_linux.image_id
  instance_type = "t3.micro"

  subnet_id = var.public_subnet_id

  vpc_security_group_ids = [var.bastion_sg_id]

  associate_public_ip_address = true

  key_name = var.key_name

  tags = {
    Name = "bastion-host"
  }
}

#Private EC2 - App Server
resource "aws_instance" "app_server" {
  #Fix Hardcoded AMI
  ami           = data.aws_ami.amazon_linux.image_id
  instance_type = "t3.micro"

  subnet_id = var.private_subnet_id

  vpc_security_group_ids = [var.app_sg_id]

  associate_public_ip_address = false

  key_name = var.key_name

  tags = {
    Name = "app-server"
  }
}