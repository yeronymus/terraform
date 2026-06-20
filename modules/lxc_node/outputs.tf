output "container_ip" {
  value       = var.ip_address
  description = "The static IP of the container"
}

output "root_password" {
  value       = random_password.root_password.result
  sensitive   = true
  description = "The randomly generated root password"
}
