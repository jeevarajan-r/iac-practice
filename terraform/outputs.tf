output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "private_key" {
  value     = tls_private_key.app_key.private_key_pem
  sensitive = true
}

output "app_url" {
  value = "http://${aws_instance.app.public_ip}:5000"
}