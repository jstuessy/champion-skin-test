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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = aws_vpc.main.cidr_block
  availability_zone = "${data.aws_region.current.name}a"
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "mfi_route_table_association" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.main.id
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

resource "aws_key_pair" "aws_deployer_key" {
  key_name   = "aws_deployer_key"
  public_key = tls_private_key.deployer_key.public_key_openssh
}

resource "aws_instance" "web" {
  count                       = 3
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.aws_deployer_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_http.id, aws_security_group.allow_ssh.id]
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