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

resource "aws_security_group" "allow_consul" {
  name        = "allow_consul"
  description = "Allow Consul traffic"

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

resource "aws_eip" "elastic_ip" {
  count                     = 3
  vpc                       = true
  instance                  = aws_instance.web[count.index].id
  associate_with_private_ip = aws_instance.web[count.index].private_ip
}

# TODO: Rename, "eip_assoc" is a bad name
resource "aws_eip_association" "eip_assoc" {
  count         = 3
  instance_id   = aws_instance.web[count.index].id
  allocation_id = aws_eip.elastic_ip[count.index].id
}

resource "tls_private_key" "deployer_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# TODO: Rename to "deployer_public_key"
resource "aws_key_pair" "aws_deployer_key" {
  key_name   = "aws_deployer_key"
  public_key = tls_private_key.deployer_key.public_key_openssh
}

resource "aws_instance" "web" {
  count                       = 3
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.aws_deployer_key.key_name
  vpc_security_group_ids      = [aws_security_group.allow_consul.id, aws_security_group.allow_ssh.id]
  tags = {
    subject = "consul"
    context = "master"
    owner   = "champion-skinner"
  }
}

resource "local_file" "aws_public_deploy_key" {
  content              = tls_private_key.deployer_key.public_key_pem
  filename             = pathexpand("~/.ssh/aws_ec2_rsa.pub.pem")
  file_permission      = "600"
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

output "web_public_ip_0" {
  value = aws_instance.web[0].public_ip
}

output "web_public_ip_1" {
  value = aws_instance.web[1].public_ip
}

output "web_public_ip_2" {
  value = aws_instance.web[2].public_ip
}
