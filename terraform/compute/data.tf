data "aws_ami" "amazon_linux" {
  # Can lead to EC2 replacement
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

data "aws_ami" "custom_ami" {
  most_recent = true

  owners = ["self"]

  filter {
    name   = "name"
    values = ["travel-app-docker-ami-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}