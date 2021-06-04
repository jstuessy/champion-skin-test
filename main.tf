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

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH traffic"
  ingress {
    description = "SSH"
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_consul_server" {
  name        = "allow_consul_server"
  description = "Allow Consul Server traffic"

  # TODO: Switch to make it so only in-network machines can talk to each other
  # TODO: ["0.0.0.0/0"] -> ["0.0.0.0/0", "::/0"]
  ingress {
    description = "HTTP"
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "DNS"
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "DNS udp"
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Lan Serf"
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Lan Serf udp"
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Wan Serf"
    from_port   = 8302
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Wan Serf udp"
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Server RPC"
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_eip" "consul_elastic_ip" {
#   count                     = 3
#   vpc                       = true
#   instance                  = aws_instance.consul[count.index].id
#   associate_with_private_ip = aws_instance.consul[count.index].private_ip
# }

# resource "aws_eip_association" "consul_elastic_ip_association" {
#   count         = 3
#   instance_id   = aws_instance.consul[count.index].id
#   allocation_id = aws_eip.consul_elastic_ip[count.index].id
# }

# resource "aws_eip" "vault_elastic_ip" {
#   count                     = 3
#   vpc                       = true
#   instance                  = aws_instance.vault[count.index].id
#   associate_with_private_ip = aws_instance.vault[count.index].private_ip
# }

# resource "aws_eip_association" "vault_elastic_ip_association" {
#   count         = 3
#   instance_id   = aws_instance.vault[count.index].id
#   allocation_id = aws_eip.vault_elastic_ip[count.index].id
# }

resource "tls_private_key" "deployer_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer_public_key" {
  key_name   = "deployer_public_key"
  public_key = tls_private_key.deployer_key.public_key_openssh
}

resource "aws_instance" "consul" {
  count                  = 3
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer_public_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_consul_server.id, aws_security_group.allow_ssh.id]
  tags = {
    subject = "consul-server"
    context = "master"
    owner   = "champion-skinner"
  }
}

resource "aws_instance" "vault" {
  count                  = 3
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer_public_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    subject = "vault"
    context = "master"
    owner   = "champion-skinner"
  }
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

output "current_region" {
  value = data.aws_region.current.name
}

output "consul_public_ip_0" {
  value = aws_instance.consul[0].public_ip
}

output "consul_public_ip_1" {
  value = aws_instance.consul[1].public_ip
}

output "consul_public_ip_2" {
  value = aws_instance.consul[2].public_ip
}

output "vault_public_ip_0" {
  value = aws_instance.vault[0].public_ip
}

output "vault_public_ip_1" {
  value = aws_instance.vault[1].public_ip
}

output "vault_public_ip_2" {
  value = aws_instance.vault[2].public_ip
}
