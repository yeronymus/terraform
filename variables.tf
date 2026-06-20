variable "proxmox_api_endpoint" {
  description = "The Proxmox VE API endpoint URL"
  type        = string
}

variable "proxmox_api_token" {
  description = "The Proxmox API token in username@realm!tokenid=secret format"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "The public SSH key to inject into the test LXC container"
  type        = string
}
