variable "node_name" {
  description = "Name of the Proxmox node"
  type        = string
  default     = "pve-node"
}

variable "vm_id" {
  description = "The VM ID for the container"
  type        = number
}

variable "hostname" {
  description = "The hostname for the container"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM memory size in MB"
  type        = number
  default     = 2048
}

variable "swap" {
  description = "Swap memory size in MB"
  type        = number
  default     = 512
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 8
}

variable "ip_address" {
  description = "Static IP configuration (CIDR format e.g. 192.168.10.99/24)"
  type        = string
}

variable "gateway" {
  description = "Default gateway IP address"
  type        = string
  default     = "192.168.10.1"
}

variable "ssh_public_key" {
  description = "Public SSH key for container root access"
  type        = string
}

variable "template_file_id" {
  description = "Template volume/file ID"
  type        = string
  default     = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
}
