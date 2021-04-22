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

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  count = 3
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  tags = {
    subject = "consul"
    context = "master"
    owner   = "champion-skinner"
  }
}

resource "aws_eip" "elastic_ip" {
  count = 3
  vpc                       = true
  instance                  = aws_instance.web[count.index].id
  associate_with_private_ip = aws_instance.web[count.index].private_ip
}