# Homelab-as-Code

A repository for automating the deployment and configuration of a personal homelab based on Proxmox VE.

---

## Architecture Overview

```
packer build          →   Proxmox Template (Debian 12 + Docker)
                                ↓
terraform apply       →   LXC Node (cloned from template, ready in ~15s)
                                ↓
ansible-playbook      →   Runtime configuration updates (optional)
```

1. **Image Building (Packer):** Produces a "golden" Debian 12 VM template with Docker pre-installed. Stored in Proxmox as a reusable template. New nodes are provisioned from this image — no package installation at runtime.
2. **Orchestration (Terraform):** LXC container provisioning on Proxmox VE via the `bpg/proxmox` provider.
   * **Modularity:** Container specifications are isolated into a reusable `modules/lxc_node` local module.
   * **State Backend:** State tracking (`.tfstate`) and state locking are managed via a PostgreSQL database (`pg` backend) to prevent concurrent modifications.
3. **Configuration Management (Ansible):** Installs Docker and configures OS-level settings. Used for runtime updates on existing nodes.
   * **ProxyJump:** SSH traffic to internal containers is tunneled through the Proxmox host.
4. **CI/CD (GitHub Actions):** Automates `fmt`, `validate`, and `ansible-lint` on every push.

---

## Directory Structure

```text
.
├── .github/workflows/
│   └── iac-validation.yml      # GitHub Actions validation pipeline
├── packer/
│   ├── debian-docker.pkr.hcl   # Packer build: Debian 12 + Docker golden image
│   ├── packer.pkrvars.hcl.example
│   ├── http/
│   │   └── preseed.cfg         # Debian unattended install config
│   └── scripts/
│       └── install-docker.sh   # Docker installation script
├── modules/
│   └── lxc_node/               # Reusable LXC container module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── provider.tf                  # Provider setup & pg backend configuration
├── variables.tf                 # Input variable declarations
├── terraform.tfvars             # Secrets & local overrides (git-ignored)
└── ansible/
    ├── ansible.cfg              # SSH ProxyJump & connection configuration
    ├── inventory.ini            # Target host inventory
    └── playbooks/
        └── setup_node.yml       # Docker setup & OS packages playbook
```

---

## How to Run

### 0. Build the Golden Image (Packer)

Run once to create the Debian 12 + Docker template in Proxmox. Subsequent `terraform apply` runs use this template and skip all package installation.

```bash
cd packer
cp packer.pkrvars.hcl.example packer.pkrvars.hcl
# Fill in proxmox_api_token_secret and ssh_public_key in packer.pkrvars.hcl

../packer-bin init .
../packer-bin validate -var-file=packer.pkrvars.hcl .
../packer-bin build -var-file=packer.pkrvars.hcl .
```

> **Note:** The ISO `debian-12.10.0-amd64-netinst.iso` must be present in `local:iso/` on the Proxmox node before building.

### 1. Provision Infrastructure (Terraform)

Initialize with the PostgreSQL backend (keeps secrets out of source control):
```bash
./terraform init -reconfigure \
  -backend-config="conn_str=postgres://<user>:<password>@<db-host>:15432/terraform_state?sslmode=disable"
```

Dry-run plan:
```bash
./terraform plan
```

Apply:
```bash
./terraform apply
```

### 2. Configure Existing Nodes (Ansible)

```bash
cd ansible
python3 -m venv venv && ./venv/bin/pip install ansible-core
./venv/bin/ansible-playbook -i inventory.ini playbooks/setup_node.yml
```
