# Homelab-as-Code

A repository for automating the deployment and configuration of a personal homelab based on Proxmox VE.

---

## Architecture Overview

1. **Orchestration (Terraform):** LXC container provisioning on Proxmox VE via the `bpg/proxmox` provider.
   * **Modularity:** Container specifications are isolated into a reusable `modules/lxc_node` local module.
   * **State Backend:** State tracking (`.tfstate`) and state locking are managed via a PostgreSQL database (`pg` backend) to prevent concurrent modifications.
2. **Configuration Management (Ansible):** Automatically installs Docker and configures the Debian 12 OS.
   * **ProxyJump:** SSH traffic to the internal containers is automatically tunneled through the Proxmox host.
3. **CI/CD (GitHub Actions):** Automates formatting verification (`fmt`), syntax validation (`validate`), and Ansible playbook linting (`ansible-lint`) on every push.

---

## Directory Structure

```text
.
├── .github/workflows/
│   └── iac-validation.yml   # GitHub Actions validation pipeline
├── terraform/
│   ├── provider.tf          # Provider setup & pg backend configuration
│   ├── variables.tf         # Input variable declarations
│   ├── terraform.tfvars     # Secrets & local overrides (git-ignored)
│   ├── main.tf              # Module invocations
│   └── modules/
│       └── lxc_node/        # Reusable LXC container module
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
└── ansible/
    ├── ansible.cfg          # SSH ProxyJump & connection configurations
    ├── inventory.ini        # Target host inventory
    └── playbooks/
        └── setup_node.yml   # Docker setup & OS packages playbook
```

---

## How to Run

### 1. Provision Infrastructure (Terraform)
Initialize the directory and pass the PostgreSQL connection string dynamically to keep secrets out of source control:
```bash
./terraform init -reconfigure -backend-config="conn_str=postgres://<user>:<password>@<db-host>:15432/terraform_state?sslmode=disable"
```
Perform a dry-run plan:
```bash
./terraform plan
```
Apply the changes:
```bash
./terraform apply
```

### 2. Configure Node (Ansible)
```bash
cd ansible
# Setup Python virtual environment & install Ansible
python3 -m venv venv && ./venv/bin/pip install ansible-core

# Run the setup playbook
./venv/bin/ansible-playbook -i inventory.ini playbooks/setup_node.yml
```

---

## TODO / Roadmap

- [ ] **Packer Integration:** Automate building "golden OS images" (Debian templates with pre-installed Docker and Tailscale) to speed up container booting and bypass runtime package installs.
