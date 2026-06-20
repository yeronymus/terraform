packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# ---------------------------------------------------------------------------
# Variables — values passed via packer.pkrvars.hcl or env vars (PKR_VAR_*)
# ---------------------------------------------------------------------------

variable "proxmox_api_url" {
  type    = string
  default = "https://100.90.175.9:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type    = string
  default = "terraform-prov@pve!tf-token"
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type = string
}

# ---------------------------------------------------------------------------
# Source: boot a minimal Debian 12 ISO, run preseed, then install Docker
# ---------------------------------------------------------------------------

source "proxmox-iso" "debian-docker" {
  # Proxmox connection
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = true

  # Node and template metadata
  node                 = "pve-node"
  vm_id                = 9000
  template_name        = "debian-12-docker-golden"
  template_description = "Debian 12 + Docker CE. Built by Packer on ${formatdate("YYYY-MM-DD", timestamp())}."

  # Boot ISO (new block format — proxmox plugin >= 1.1)
  boot_iso {
    iso_file = "local:iso/debian-12.10.0-amd64-netinst.iso"
    unmount  = true
  }

  # Hardware
  cores  = 2
  memory = 2048
  os     = "l26"

  disks {
    type         = "scsi"
    disk_size    = "20G"
    storage_pool = "local-lvm"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Cloud-init drive for post-boot configuration
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # Boot command — trigger Debian unattended install via preseed served from
  # Packer's built-in HTTP server
  boot_wait    = "10s"
  boot_command = [
    "<esc><wait>",
    "auto url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "hostname=packer-build domain=local",
    "<enter>"
  ]

  # Serve preseed.cfg via built-in HTTP server (relative to this .pkr.hcl)
  http_directory = "http"
  http_port_min  = 8802
  http_port_max  = 8802

  # SSH access for provisioner (password set in preseed.cfg)
  communicator         = "ssh"
  ssh_username         = "root"
  ssh_private_key_file = "~/.ssh/id_ed25519"
  ssh_timeout          = "30m"
}

# ---------------------------------------------------------------------------
# Build: provision Docker, then clean up for templating
# ---------------------------------------------------------------------------

build {
  name    = "debian-12-docker-golden"
  sources = ["source.proxmox-iso.debian-docker"]

  provisioner "shell" {
    execute_command = "bash {{.Path}}"
    # Path is relative to the packer/ directory (where packer build is run)
    script = "${path.root}/scripts/install-docker.sh"
  }

  provisioner "shell" {
    inline = [
      "apt-get autoremove -y -qq",
      "apt-get clean",
      "rm -rf /tmp/* /var/tmp/*",
      "truncate -s 0 /etc/machine-id",
      "truncate -s 0 /var/lib/dbus/machine-id",
      "cloud-init clean"
    ]
  }
}
