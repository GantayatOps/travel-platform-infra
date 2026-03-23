resource "aws_instance" "bastion_host" {
  #Fix Hardcoded AMI
  ami           = "ami-022062aacfecac5bd"
  instance_type = "t3.micro"

  subnet_id = var.public_subnet_id

  vpc_security_group_ids = [var.bastion_sg_id]

  associate_public_ip_address = true

  tags = {
    Name = "bastion-host"
  }
}