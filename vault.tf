resource "aws_instance" "vault_server" {
  count                  = 3
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer_public_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_vault_server.id, aws_security_group.allow_ssh.id, aws_security_group.allow_consul_client.id]
  tags = {
    subject = "vault-server"
    owner   = "champion-skinner"
  }
}
