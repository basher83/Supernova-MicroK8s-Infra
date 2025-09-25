# Ansible Infrastructure Automation

## Directory Structure

```text
ansible/
├── ansible.cfg              # Ansible configuration (inventory, SSH, caching)
├── requirements.yml         # Required Ansible collections
├── group_vars/
│   └── all.yml             # Global variables (network, hosts, services)
├── inventory/              # Dynamic inventory configurations
│   ├── hosts.yml          # Main inventory (Proxmox dynamic)
│   ├── inventory.ini      # Static fallback inventory
│   └── production.yml     # Production environment inventory
├── playbooks/             # Orchestration playbooks
│   ├── playbook.yml       # Main deployment (MicroK8s + Rancher + ArgoCD)
│   └── examples/          # Pattern demonstrations and working examples
├── roles/                 # Reusable automation components
│   ├── argocd/           # ArgoCD deployment and configuration
│   ├── microk8s_cluster/ # MicroK8s HA cluster management
│   ├── microk8s_install/ # MicroK8s base installation
│   ├── microk8s-addons/  # MicroK8s addon management
│   └── rancher/          # Rancher deployment and configuration
└── tasks/                # Reusable task files
    └── infisical-secret-lookup.yml  # Advanced secret retrieval patterns
```

## Quick Start

```bash
# Install dependencies
uv run ansible-galaxy collection install -r requirements.yml

# Run main deployment
uv run ansible-playbook playbooks/playbook.yml

# Run examples
uv run ansible-playbook playbooks/examples/infisical-demo.yml
```

## Key Components

### Configuration (`ansible.cfg`)

- **Inventory**: Dynamic Proxmox-based discovery
- **SSH**: Optimized connection settings with ControlMaster
- **Caching**: JSON fact caching (24h TTL)
- **Output**: YAML callback with diff display
- **Security**: Host key checking disabled for development

### Variables (`group_vars/all.yml`)

- Network configuration (home/cluster networks)
- Host definitions (masters, workers, jumpbox)
- Service hostnames (Rancher, ArgoCD)
- SSH proxy configuration

### Inventory

- **Primary**: `hosts.yml` - Dynamic Proxmox inventory
- **Fallback**: `inventory.ini` - Static inventory
- **Production**: `production.yml` - Environment-specific config

### Playbooks

- **`playbook.yml`**: Complete MicroK8s cluster deployment with Rancher and ArgoCD
- **`examples/`**: Working examples (Infisical) and pattern demonstrations

### Roles (Ansible Galaxy Standard)

Each role follows: `defaults/` `handlers/` `meta/` `tasks/` `tests/` `vars/`

- **microk8s_install**: Base MicroK8s installation
- **microk8s_cluster**: HA cluster formation
- **microk8s-addons**: Service enablement (DNS, storage, ingress)
- **rancher**: Rancher deployment via Helm
- **argocd**: ArgoCD deployment via Helm

## Standards & Patterns

- **Secrets**: Infisical integration with environment fallbacks
- **Validation**: Pre-flight checks and assertions
- **Idempotency**: Safe re-runs with state checking
- **Tags**: Granular execution control (`install`, `configure`, `validate`)
- **Documentation**: Role READMEs and inline comments

See [Ansible Standards](../docs/standards/ansible-standards.md) for detailed patterns and best practices.

## Environment Setup

Required environment variables:

```bash
# Infisical authentication (retrieves all secrets including Proxmox)
INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=...
INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=...
```

All infrastructure secrets (Proxmox credentials, service tokens, etc.) are retrieved from Infisical. See `tasks/infisical-secret-lookup.yml` for advanced secret retrieval patterns.

## Testing

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/playbook.yml

# Dry run
uv run ansible-playbook --check --diff playbooks/playbook.yml

# Lint roles
uv run ansible-lint roles/
```
