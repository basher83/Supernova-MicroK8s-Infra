# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Supernova-MicroK8s-Infra is a homelab infrastructure-as-code project that automates deployment of a production-ready MicroK8s Kubernetes cluster on Proxmox. The project uses Terraform for VM provisioning and Ansible for cluster configuration, deploying MicroK8s, Rancher, and ArgoCD in an isolated homelab environment.

## Development Environment Setup

This project uses **mise** (formerly rtx) for tool management. All development tools are defined in `.mise.toml`.

```bash
# Initial setup
mise install                    # Install all required tools
mise run setup                  # Install hooks and generate docs
mise run pip-install           # Install Python dependencies (Ansible)
mise run ansible-setup         # Install Ansible collections

# Verify setup
mise doctor                     # Check mise configuration
```

## Common Development Commands

### Terraform Workflows

```bash
# Format and validate
mise run fmt                    # Format Terraform files
mise run fmt-check             # Check formatting (CI-friendly)
mise run prod-validate         # Validate Terraform configuration
mise run lint-prod             # Run TFLint

# Documentation
mise run docs                   # Generate Terraform docs
mise run docs-check            # Verify docs are up-to-date

# Complete checks
mise run check                  # Format, lint, and validate
mise run full-check            # Complete validation including security

# Terraform operations (from terraform/ directory)
mise run plan                   # Run terraform plan
mise run apply                  # Run terraform apply
mise run destroy               # Run terraform destroy
```

### Ansible Workflows

```bash
# From ansible/ directory
mise run ansible-install        # Install Ansible requirements
mise run ansible-ping          # Test connectivity to all hosts

# Run playbooks
ansible-playbook playbooks/playbook.yml                    # Main deployment
ansible-playbook --syntax-check playbooks/playbook.yml    # Syntax check
ansible-playbook --check --diff playbooks/playbook.yml    # Dry run
```

### Linting and Validation

```bash
mise run lint-all              # Run all linters (shell, YAML, Markdown, Terraform, Ansible)
mise run shellcheck            # Lint shell scripts
mise run yaml-lint             # Lint YAML files
mise run markdown-lint         # Lint Markdown files
mise run ansible-lint          # Lint Ansible playbooks/roles
```

### Formatting

```bash
mise run fmt-all               # Format all files (Terraform and YAML)
mise run yaml-fmt              # Format YAML files
```

### Pre-commit Hooks

```bash
mise run hooks-install         # Install pre-commit and infisical hooks
mise run hooks-run             # Run all pre-commit hooks
mise run infisical-scan        # Scan for secrets
```

### Version Management

```bash
mise run changelog             # Update CHANGELOG.md using git-cliff
```

## Repository Architecture

### High-Level Structure

The project follows a dual-layer IaC approach:

1. **Terraform Layer** (`terraform/`): Provisions VMs on Proxmox (infrastructure)
2. **Ansible Layer** (`ansible/`): Configures MicroK8s cluster, deploys Rancher and ArgoCD (configuration)

This separation ensures clean boundaries between infrastructure provisioning and application configuration.

### Terraform Module System

The Terraform codebase uses a **modular architecture** organized into three tiers:

```
terraform/
├── modules/              # Reusable modules (building blocks)
│   ├── vm/              # New unified VM module (flexible)
│   ├── vm-clone/        # Legacy: Clone from template
│   ├── vm-template/     # Legacy: Create VM template
│   ├── image/           # Download cloud images
│   └── lxc/             # LXC container management
├── deployments/         # Environment-specific deployments
│   └── testing/
│       └── single_vm_clone/  # Example deployment
└── bgp-example/         # BGP routing examples
```

**Key Architecture Principles:**

- **modules/**: Reusable building blocks with no hardcoded values. Accept all configuration via variables.
- **deployments/**: Environment-specific configurations (testing, staging, production). Call modules with specific values.
- **Legacy modules** (vm-clone, vm-template): Transitioning to unified `vm/` module which supports both templates and clones via `vm_type` variable.

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

```
ansible/
├── ansible.cfg          # Proxmox dynamic inventory, SSH optimization, fact caching
├── inventory/           # Dynamic (Proxmox) and static inventory files
├── group_vars/all.yml   # Global variables (network, hosts, services)
├── playbooks/
│   ├── playbook.yml     # Main: MicroK8s + Rancher + ArgoCD deployment
│   └── examples/        # Pattern demonstrations (Infisical integration)
└── roles/               # Galaxy-standard roles (defaults/, handlers/, tasks/, etc.)
    ├── microk8s_install/
    ├── microk8s_cluster/
    ├── microk8s-addons/
    ├── rancher/
    └── argocd/
```

**Key Features:**

- **Dynamic Inventory**: Uses Proxmox for automatic host discovery
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

- **docs/**: Architecture decisions, standards, troubleshooting guides
  - `docs/standards/ansible-standards.md`: Ansible best practices
  - `docs/terraform/`: Terraform-specific documentation
  - `docs/iac-implementation-plan.md`: Future Scalr integration plan
- **README.md**: Project overview
- **ansible/README.md**: Ansible-specific setup and patterns

## Important Patterns and Conventions

### Terraform Best Practices

1. **Module Variables**: Use `vm_clone_template_id` (not just `template_id`) for clarity when cloning VMs
2. **Cloud-init SSH Keys**: Cloud-init SSH key changes trigger forced replacement - this is expected (see lifecycle in `modules/vm-clone/main.tf:120-122`)
3. **Provider**: Uses `bpg/proxmox` provider (>=0.84.1), not the older Telmate provider
4. **Formatting**: Always run `mise run fmt` before committing
5. **Documentation**: Auto-generated via terraform-docs - run `mise run docs` after module changes

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
2. **Configure Terraform** (`terraform.tfvars`)
3. **Deploy VMs**: `cd terraform && mise run apply`
4. **Configure Cluster**: `cd ansible && ansible-playbook playbooks/playbook.yml`
5. **Verify Deployment**: Check MicroK8s, Rancher, and ArgoCD

See `tasks/INDEX.md` for detailed step-by-step guidance.

## Tool Versions

Managed via `.mise.toml`. Current key tools:

- Terraform: 1.13.3
- Python: 3.13.7
- Pre-commit: 4.3.0
- Terraform-docs: 0.20.0
- TFLint: 0.59.1
- Ansible: Installed via pip (see requirements.txt)

## Testing

```bash
# Terraform
cd terraform
terraform plan -var-file="testing.tfvars"

# Ansible
ansible-playbook --syntax-check playbooks/playbook.yml
ansible-playbook --check --diff playbooks/playbook.yml
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
- **OpenTofu**: Repository structured for future OpenTofu migration
