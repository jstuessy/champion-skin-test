output "current_region" {
  value = data.aws_region.current.name
}

output "public_ips" {
  value = tomap({
    "consul_server" = toset([
      for consul_server in aws_instance.consul_server : consul_server.public_ip
    ]),
    "vault_server" = toset([
      for vault_server in aws_instance.vault_server : vault_server.public_ip
    ]),
    "nomad_server" = toset([
      for nomad_server in aws_instance.nomad_server : nomad_server.public_ip
    ])
  })
}