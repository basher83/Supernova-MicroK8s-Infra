# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Supernova-MicroK8s-Infra is a homelab infrastructure-as-code project that automates deployment of a production-ready MicroK8s Kubernetes cluster on Proxmox. The project uses Terraform for VM provisioning and Ansible for cluster configuration, deploying MicroK8s, Rancher, and ArgoCD in an isolated homelab environment.

## Development Environment Setup

This project uses **mise** (formerly rtx) for tool management. All development tools are defined in `.mise.toml`.

## Repository Architecture

### High-Level Structure

The project follows a dual-layer IaC approach:

1. **Terraform Layer** (`terraform/`): Provisions VMs on Proxmox (infrastructure)
2. **Ansible Layer** (`ansible/`): Configures MicroK8s cluster, deploys Rancher and ArgoCD (configuration)

This separation ensures clean boundaries between infrastructure provisioning and application configuration.

### Terraform Module System

The Terraform codebase uses a **modular architecture** organized into three tiers:

```text
terraform/
├── modules/              # Reusable modules (building blocks)
│   ├── vm/              # New unified VM module (flexible)
│   ├── lxc/             # LXC container management
│   └── vm-cluster/      # Cluster management
├── deployments/         # Environment-specific deployments
│   └── testing/
│       examples/
```

**Key Architecture Principles:**

- **modules/**: Reusable building blocks with no hardcoded values. Accept all configuration via variables.
- **deployments/**: Environment-specific configurations (testing, staging, production). Call modules with specific values.

**New `vm/` Module Pattern:**

```hcl
module "pve_vm" {
  source = "../../modules/vm"

  vm_type  = "clone"  # or "template"
  pve_node = var.proxmox_node

  src_clone = {
    datastore_id = "data"
    tpl_id       = 2000
  }

  vm_name = "my-vm"
  # ... additional configuration
}
```

### Ansible Architecture

Ansible follows standard Galaxy role structure:

```text
ansible/
├── ansible.cfg          # Proxmox dynamic inventory, SSH optimization, fact caching
├── inventory/           # Dynamic (Proxmox) and static inventory files
├── group_vars/all.yml   # Global variables (network, hosts, services)
├── playbooks/
│   ├── microk8s-deploy.yml  # Main: MicroK8s + Rancher + ArgoCD deployment
│   └── examples/            # Pattern demonstrations (Infisical integration)
└── roles/               # Galaxy-standard roles (defaults/, handlers/, tasks/, etc.)
    ├── microk8s_install/
    ├── microk8s_cluster/
    ├── microk8s-addons/
    ├── rancher/
    └── argocd/
```

**Key Features:**

- **Dynamic Inventory**: [WIP] Uses Proxmox for automatic host discovery
- **Secrets Management**: Infisical integration with environment fallbacks (see `tasks/infisical-secret-lookup.yml`)
- **Idempotency**: All roles designed for safe re-runs with state checking
- **Tags**: Granular execution control (`install`, `configure`, `validate`)

### Task Management System

The `tasks/` directory contains a comprehensive task tracking system for the learning journey:

- **INDEX.md**: Executive dashboard showing all tasks, phases, and progress
- **Task Categories**: PREP (prerequisites), INFRA (infrastructure), ACCESS (external access), APPS (applications), OPS (operations)
- Each task has detailed markdown files with acceptance criteria and implementation steps

Reference `tasks/INDEX.md` for deployment roadmap and learning path.

### Documentation

- Refer to @docs/INDEX.md for documentation

## Important Patterns and Conventions

### Terraform Best Practices

1. **Module Variables**: Use `vm_clone_template_id` (not just `template_id`) for clarity when cloning VMs
2. **Cloud-init SSH Keys**: Cloud-init SSH key changes trigger forced replacement - this is expected (see lifecycle in `modules/vm-clone/main.tf:120-122`)
3. **Provider**: Uses `bpg/proxmox` provider (>=0.84.1), not the older Telmate provider
4. **Formatting**: Always run `tofu fmt, tofu validate, tflint` before committing
5. **Documentation**: Auto-generated via terraform-docs - run `terraform-docs markdown . --output-file README.md` after module changes

### Ansible Best Practices

1. **Secrets**: Always use Infisical for secret retrieval with environment variable fallbacks
2. **Validation**: Include pre-flight checks and assertions in roles
3. **Documentation**: Each role must have a README with examples
4. **Testing**: Use `--check --diff` for dry runs before applying changes
5. **Inventory**: Primary inventory uses Proxmox dynamic discovery

### Git Workflow

- **Commit Messages**: Follow conventional commits (see recent commits for style)
- **Pre-commit Hooks**: Automatically enforce formatting, linting, and security scanning
- **Secrets Scanning**: Infisical scan runs on every commit
- **Branch**: Main branch is `main` (use for PRs)

### Security Considerations

1. **Never commit secrets**: Pre-commit hooks scan for credentials
2. **Infisical Authentication**: Set `INFISICAL_UNIVERSAL_AUTH_CLIENT_ID` and `INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET` environment variables
3. **SSH Keys**: Cloud-init keys are ignored in lifecycle to prevent unnecessary replacements
4. **TLS Verification**: Disabled for homelab development (not recommended for production)

## Environment Variables

Required for Ansible/Infisical integration:

```bash
export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID="..."
export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET="..."
```

All infrastructure secrets (Proxmox credentials, tokens, etc.) are retrieved from Infisical at runtime.

## Deployment Workflow

Standard deployment follows this sequence:

1. **Create Proxmox VM Template** (PREP-001 in tasks/)
2. **Configure Terraform** (`terraform.auto.tfvars`)
3. **Deploy VMs**: [WIP]: Modules are set for deployments, `terraform/deployments/*` is the location for the deployments.
4. **Configure Cluster**: `cd ansible && ansible-playbook playbooks/microk8s-deploy.yml`
5. **Verify Deployment**: Check MicroK8s, Rancher, and ArgoCD

See `tasks/INDEX.md` for detailed step-by-step guidance.

## Testing

```bash
# Terraform
cd terraform
tofu plan

# Ansible
ansible-playbook --syntax-check playbooks/microk8s-deploy.yml
ansible-playbook --check --diff playbooks/microk8s-deploy.yml
ansible-lint roles/

# Pre-commit
mise run hooks-run
```

## Troubleshooting

- **Network Issues**: Check `docs/troubleshooting/networking-vlan.md`
- **Ansible Connectivity**: Verify SSH access via jumpbox (192.168.30.240)
- **Proxmox Provider**: Consult `docs/research/proxmox-terraform-provider-comparison.md`
- **BIOS Selection**: See `docs/research/proxmox-bios-selection.md`

## Migration Notes

- **Future Plan**: Migration to Scalr for multi-environment management (see `docs/iac-implementation-plan.md`)
- **Module Consolidation**: Migrating from separate vm-clone/vm-template modules to unified `vm/` module
- **OpenTofu**: Repository has completed the migration to OpenTofu
