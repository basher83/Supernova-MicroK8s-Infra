---
Task: Create base infrastructure-microk8s directory structure with modular Terraform patterns
Task ID: TER-001
Priority: P0
Estimated Time: 3 hours
Dependencies: None
Status: 🔄 Ready
Created: 2025-09-20
Updated: 2025-09-20
---

## Objective

Create the foundational Terraform directory structure for MicroK8s infrastructure, migrating sophisticated patterns from the existing `infrastructure/` directory while adapting them for MicroK8s deployment instead of Vault/Nomad.

## Prerequisites

- [ ] Access to existing `infrastructure/` directory for reference
- [ ] Understanding of current Terraform patterns (vendor_data, modules, environments)
- [ ] Terraform 1.0+ installed locally
- [ ] Git repository access

## Implementation Steps

### 1. **Create Base Directory Structure**

```bash
# Create the new infrastructure directory
mkdir -p infrastructure-microk8s/{modules,environments,vendor-data,scripts}

# Create module directories
mkdir -p infrastructure-microk8s/modules/{microk8s-vm,microk8s-master,microk8s-worker}

# Create environment directories
mkdir -p infrastructure-microk8s/environments/{development,staging,production}

# Create supporting directories
mkdir -p infrastructure-microk8s/{scripts,docs}
```

### 2. **Set Up Base Terraform Configuration**

Create `infrastructure-microk8s/versions.tf`:

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.73.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
```

### 3. **Create Base Module Structure**

Create `infrastructure-microk8s/modules/microk8s-vm/variables.tf`:

```hcl
variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "vm_id" {
  type        = number
  description = "Proxmox VM ID"
}

variable "vm_node_name" {
  type        = string
  description = "Proxmox node to deploy VM on"
}

variable "vcpu" {
  type        = number
  description = "Number of vCPUs"
  default     = 2
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 4096
}

variable "disk_size" {
  type        = number
  description = "Disk size in GB"
  default     = 40
}

variable "vm_ip_primary" {
  type        = string
  description = "Primary IP address with CIDR"
}

variable "vm_gateway" {
  type        = string
  description = "Gateway IP address"
}

variable "template_id" {
  type        = number
  description = "Template VM ID to clone from"
}

variable "ci_ssh_key" {
  type        = string
  description = "SSH public key for cloud-init"
}
```

### 4. **Set Up Environment Template**

Create `infrastructure-microk8s/environments/development/main.tf`:

```hcl
locals {
  vm_id_offset = 3000  # Development environment offset
  env_tag      = "development"

  # Single-node development setup
  vm_instances = {
    dev-master = {
      name      = "microk8s-dev-master"
      vm_id     = local.vm_id_offset + 1
      ip        = "${var.cluster_subnet}.10/24"
      gateway   = "${var.cluster_subnet}.1"
      vcpu      = 2
      memory    = 4096
      disk_size = 40
      role      = "master"
    }
  }
}

# This will use the module once created
# module "vm" {
#   for_each = local.vm_instances
#   source   = "../../modules/microk8s-vm"
#   # Configuration will be added in next tasks
# }
```

### 5. **Create README Documentation**

Create `infrastructure-microk8s/README.md`:

```markdown
# MicroK8s Infrastructure

Terraform-based infrastructure for deploying MicroK8s clusters on Proxmox.

## Directory Structure

- `modules/` - Reusable Terraform modules
- `environments/` - Environment-specific configurations
- `vendor-data/` - Cloud-init vendor data templates
- `scripts/` - Helper scripts

## Usage

See environment-specific README files for deployment instructions.
```

## Success Criteria

- [ ] Directory structure created and organized
- [ ] Base Terraform configuration files in place
- [ ] Module structure follows existing patterns from `infrastructure/`
- [ ] Environment separation established (dev/staging/prod)
- [ ] Version requirements defined
- [ ] Initial documentation created

## Validation

```bash
# Verify directory structure
tree infrastructure-microk8s/ -L 3

# Validate Terraform configuration
cd infrastructure-microk8s/environments/development
terraform init
terraform validate

# Check that all required files exist
ls -la infrastructure-microk8s/modules/microk8s-vm/
ls -la infrastructure-microk8s/environments/
```

Expected output:
- Clean directory tree matching the planned structure
- Terraform init succeeds (downloads providers)
- No validation errors

## Notes

- Keep existing `infrastructure/` directory for reference
- Use consistent naming patterns from existing codebase
- Ensure all Terraform files follow HCL best practices
- Consider using symlinks for shared configurations initially

## References

- [Planning Document](../../docs/planning.md) - Section on "Target Architecture"
- Existing patterns in `infrastructure/modules/vm/`
- [Terraform Module Documentation](https://www.terraform.io/docs/language/modules/develop/index.html)