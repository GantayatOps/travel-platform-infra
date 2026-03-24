# Bastion Host(Public Subnet)
resource "aws_instance" "bastion_host" {
  #Fix Hardcoded AMI
  ami           = "ami-022062aacfecac5bd"
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
  ami           = "ami-022062aacfecac5bd"
  instance_type = "t3.micro"

  subnet_id = var.private_subnet_id

  vpc_security_group_ids = [var.app_sg_id]

  associate_public_ip_address = false

  key_name = var.key_name

  tags = {
    Name = "app-server"
  }
}