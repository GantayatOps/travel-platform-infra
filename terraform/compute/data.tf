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