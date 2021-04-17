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
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

}

resource "aws_eip" "elastic_ip" {
 vpc = true
 instance = aws_instance.web.id
 associate_with_private_ip = aws_instance.web.private_ip
}

resource "local_file" "AnsibleInventory" {
  content = templatefile("inventory.tmpl",
    {
      web-dns = aws_eip.elastic_ip.public_dns,
      web-ip = aws_eip.elastic_ip.public_ip,
      web-id = aws_instance.web.id
    }
  )
  filename = "inventory"
}
