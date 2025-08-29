# Infrastructure Configuration 💫

**Self-Provisioning Infrastructure with Cloud-Init Automation**

This directory contains all Terraform-related code for provisioning and managing the homelab infrastructure. The infrastructure features complete automation with cloud-init, including automatic software installation, configuration, and service setup.

## 🚀 Automation Features

### Enhanced Cloud-Init Integration

Our infrastructure leverages advanced cloud-init configurations to provide:

✅ **Complete Software Installation** - Vault, dependencies, repositories
✅ **DNS Configuration** - Reliable internet connectivity (8.8.8.8, 8.8.4.4)
✅ **QEMU Guest Agent** - Seamless Terraform lifecycle management
✅ **Service Configuration** - Systemd services configured and enabled
✅ **Security Hardening** - Proper permissions and user accounts
✅ **Multi-Node Distribution** - Vendor-data snippets deployed across cluster

### What Gets Deployed Automatically

When you run `terraform apply` on any environment, VMs are fully configured with:

- 🔐 **HashiCorp Vault** (v1.20.2+) - Installed from official repository
- ⚙️ **Configuration Files** - Ready-to-use Vault configurations
- 💾 **Storage Setup** - Data and logs directories with proper permissions
- 🔧 **System Services** - Vault service configured but not started (requires initialization)
- 🌐 **Network Configuration** - DNS and connectivity properly configured
- 📚 **Documentation** - Auto-generated guides and helper scripts

### Technical Implementation

- **User Data**: Terraform manages SSH keys, network configuration, user accounts
- **Vendor Data**: Enhanced cloud-init snippets handle software installation
- **DNS Integration**: Terraform configures reliable DNS servers
- **Multi-Node Support**: Cloud-init snippets distributed to all Proxmox nodes

## Directory Structure

- **environments/** - Environment-specific Terraform configurations
  - **development/** - Development environment
  - **staging/** - Staging environment
  - **production/** - Production environment
- **modules/** - Reusable Terraform modules
  - **vm/** - VM provisioning module
- **versions.tf** - Global Terraform version constraints

## Remote State and Variables (Scalr)

This project uses Scalr for state management and variable storage. Environment-specific variables are configured in Scalr workspaces (not local `terraform.tfvars` files).

## Usage

Each environment directory contains a complete Terraform configuration:

### Initialize Terraform

```bash
cd environments/staging
terraform init
```

### Plan Changes

```bash
terraform plan
```

### Apply Changes

```bash
terraform apply
```

## Modules

### VM Module

The VM module provides standardized VM provisioning for Proxmox with the following features:

- Standard VM sizing and configuration
- Two-network setup (management + application)
- Cloud-init integration
- Tagging for environment and role

Usage:

```hcl
module "vm" {
  source = "../../modules/vm"

  vm_name         = "nomad-server-1"
  vm_id           = 3101
  vm_ip_primary   = "192.168.10.11/24"
  vm_gateway      = "192.168.10.1"
  vm_ip_secondary = "192.168.11.11/24"
  vm_node_name    = "proxmox-node-1"

  // Additional optional parameters
  vcpu            = 4
  memory          = 4096
  // ...
}
```

## Variable Management

### Scalr Variables

Note: State and variables are now managed in Scalr (not Terraform Cloud).

Key variables managed in Scalr workspaces:

| Variable | Type | Sensitive | Example |
|----------|------|-----------|----------|
| **pve_api_url** | string | No | `https://proxmox.example.com:8006/api2/json` |
| **pve_api_token** | string | **Yes** | `user@pam!tokenid=secret-token-value` |
| **vm_datastore** | string | No | `local-lvm` |
| **vm_bridge_1** | string | No | `vmbr0` |
| **vm_bridge_2** | string | No | `vmbr1` |
| **ci_ssh_key** | string | No | `ssh-rsa AAAAB3...` (public key only) |

To manage these variables:

1. Log in to Scalr.
2. Navigate to the appropriate workspace.
3. Go to the Variables section.
4. Add or update workspace variables as needed.

For more details, see the [Scalr Variables documentation](https://docs.scalr.com/en/latest/workspaces/variables.html).

## Outputs

Each environment produces outputs that can be used by other tools:

- VM IP addresses and hostnames
- Network information
- Cluster details

These outputs are used to generate Ansible inventories and other configuration files.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.73.2 |
## Providers

No providers.
## Modules

No modules.
## Resources

No resources.
## Inputs

No inputs.
## Outputs

No outputs.
<!-- END_TF_DOCS -->
