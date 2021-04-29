output "private-key" {
  value = tls_private_key.private-key.private_key_pem
  sensitive = true
}

output "public_key_openssh" {
  value = tls_private_key.private-key.public_key_openssh
}
