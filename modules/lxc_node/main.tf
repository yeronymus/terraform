terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.60.1"
    }
  }
}

resource "random_password" "root_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "proxmox_virtual_environment_container" "lxc_container" {
  description = "Managed by Terraform - Homelab Node"
  node_name   = var.node_name
  vm_id       = var.vm_id

  unprivileged = true

  features {
    nesting = true
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = random_password.root_password.result
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr1"
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.disk_size
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = "debian"
  }
}
