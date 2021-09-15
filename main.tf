data "aws_region" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # This is the Canonical primary key in the AMI registry
}

resource "tls_private_key" "deployer_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer_public_key" {
  key_name   = "deployer_public_key"
  public_key = tls_private_key.deployer_key.public_key_openssh
}

resource "local_file" "aws_public_deploy_key" {
  content              = tls_private_key.deployer_key.public_key_pem
  filename             = pathexpand("~/.ssh/aws_ec2_rsa.pub.pem")
  file_permission      = "644"
  directory_permission = "700"
}

resource "local_file" "aws_private_deploy_key" {
  content              = tls_private_key.deployer_key.private_key_pem
  filename             = pathexpand("~/.ssh/aws_ec2_rsa.pem")
  file_permission      = "600"
  directory_permission = "700"
}