---
Task ID: PREP-002
Title: Configure terraform.tfvars from example
Priority: P0
Duration: 30m
Dependencies: PREP-001
Status: ✅ Complete
Created: 2025-09-25
Updated: 2025-09-30
---

## Objective

Configure Terraform variables by copying and customizing terraform.tfvars.example to create terraform.tfvars file with proper Proxmox settings, VM template ID, network configuration, and SSH credentials for deploying 3 VMs (3 MicroK8s nodes).

## Success Criteria

- [x] terraform.tfvars file created with all required variables
- [x] Proxmox credentials and endpoint configured
- [x] Template ID set to 7024 (from PREP-001)
- [x] SSH public key configured
- [x] Network settings validated for dual network setup
- [x] VM specifications confirmed within available resources
- [x] `terraform plan` runs successfully without errors
- [x] Cross-node VM cloning implemented (template on lloyd → VMs on lloyd, holly, mable)
- [x] VM tagging system configured
- [x] VMs successfully deployed across all three Proxmox nodes

## Prerequisites

- PREP-001 completed (VM template created with ID 7024)
- Proxmox server accessible at configured endpoint
- SSH key pair generated (or available)
- Knowledge of Proxmox node name and network bridges

## Implementation Steps

### 1. Copy Example Configuration

```bash
cd /Users/basher8383/dev/infra-as-code/Supernova-MicroK8s-Infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure Proxmox Connection

Edit terraform.tfvars and set:

- `pve_api_token`: Your Proxmox API token (create in Proxmox UI: Datastore > API Tokens)
- `pve_api_url`: Update IP if different from "https://192.168.1.100:8006/"
- `target_node`: Your Proxmox node name (check in Proxmox UI)

### 3. Set Template Configuration

Update these values:

- `template_id`: Set to "7024" (VM template from PREP-001)

### 4. Configure SSH Access

Generate SSH key if needed:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/microk8s_key -N ""
```

Set `ssh_public_key` to your public key content:

```bash
cat ~/.ssh/microk8s_key.pub
```

### 5. Validate Network Configuration

Review and adjust if needed:

- `cluster_network`: 192.168.4.0/24 subnet for cluster communication
- Ensure bridges (vmbr0, vmbr1) exist in Proxmox

### 6. Review VM Specifications

Verify VM resources match available capacity:

- MicroK8s Nodes: 2 cores, 4GB RAM, 32GB disk each

## Validation Commands

```bash
# Navigate to terraform directory
cd /Users/basher8383/dev/infra-as-code/Supernova-MicroK8s-Infra/terraform

# Check configuration file exists
ls -la terraform.tfvars

# Validate Terraform configuration
terraform init
terraform validate

# Test configuration with plan (should succeed without errors)
terraform plan
```

## Learning Objectives

- Understand Terraform variable configuration patterns
- Learn Proxmox VM deployment parameters
- Practice dual network configuration for Kubernetes clusters
- Experience infrastructure-as-code validation workflow

## Actual Implementation

### Configuration Summary

Final [terraform.tfvars](../../../terraform/terraform.tfvars) configuration:

```hcl
# Proxmox Configuration
pve_api_url          = "https://192.168.10.2:8006/"
pve_api_token        = "terraform@pve!scalr=<token>"
proxmox_insecure     = true
proxmox_ssh_username = "root"

# Template Configuration
template_id = 7024  # Ubuntu 22.04 LTS template created in PREP-001

# Environment
environment = "homelab"

# Dual Network Configuration
home_network = {
  gateway = "192.168.30.1"
  bridge  = "vmbr0"
}

cluster_network = {
  gateway     = "192.168.4.1"
  bridge      = "vmbr1"
  cidr_suffix = "/24"
}

# VM Specifications
node_specs = {
  cpu_cores = 2
  memory    = 4096  # 4GB RAM per node
}

# Hardware Configuration
machine_type      = "q35"        # Modern machine type
bios_type         = "ovmf"       # UEFI BIOS
efi_disk_enabled  = true
disk_datastore_id = "local-lvm"
disk_size         = 32           # 32GB per VM
```

### Critical Module Changes

#### 1. Cross-Node Template Cloning

**Problem**: Template on single node (lloyd) couldn't clone to other nodes (holly, mable)

**Solution**: Added `template_node` parameter to specify source node in clone block

[terraform/modules/proxmox-vm/main.tf](../../../terraform/modules/proxmox-vm/main.tf):

```hcl
clone {
  vm_id        = var.template_id
  node_name    = var.template_node  # ← Critical: Source node where template exists
  full         = true
  datastore_id = var.disk_datastore_id
}
```

[terraform/modules/proxmox-vm/variables.tf](../../../terraform/modules/proxmox-vm/variables.tf):

```hcl
variable "template_node" {
  description = "The Proxmox node where the template exists"
  type        = string
  default     = "lloyd"
}
```

#### 2. VM Tagging System

[terraform/main.tf](../../../terraform/main.tf):

```hcl
module "vm" {
  for_each = local.vm_instances

  # ... other configuration ...

  tags = [
    var.environment,      # "homelab"
    each.value.role,      # "microk8s-node" or "jumpbox"
    local.node_assignments[each.key].node,  # "lloyd", "holly", or "mable"
    "microk8s-cluster"
  ]
}
```

#### 3. Node Assignment Distribution

[terraform/locals.tf](../../../terraform/locals.tf):

```hcl
node_assignments = {
  jumpbox    = { node = "holly", template_id = var.template_id, source_node = "lloyd" }
  microk8s-1 = { node = "lloyd", template_id = var.template_id, source_node = "lloyd" }
  microk8s-2 = { node = "mable", template_id = var.template_id, source_node = "lloyd" }
  microk8s-3 = { node = "holly", template_id = var.template_id, source_node = "lloyd" }
}
```

**Result**: VMs distributed across 3 Proxmox nodes for high availability:
- jumpbox (VM 399) → holly
- microk8s-1 (VM 311) → lloyd
- microk8s-2 (VM 312) → mable
- microk8s-3 (VM 313) → holly

## Troubleshooting

### Issues Encountered During Implementation

#### 1. Cross-Node Clone Failure

**Error**:
```
VM 312 is running - destroy failed
```

**Root Cause**: Attempting to clone template from different node without specifying source node

**Fix**: Add `node_name` parameter to clone block specifying source node (lloyd)

**Reference**: Solution found in [basher83/Hercules-Vault-Infra](https://github.com/basher83/Hercules-Vault-Infra) repository

#### 2. EFI Disk Format Error

**Error**:
```
Parameter verification failed. (efidisk0: invalid format - missing key in comma-separated list property)
```

**Root Cause**: Missing `file_format` parameter in efi_disk block

**Fix**: Add `file_format = "raw"` to efi_disk configuration:

```hcl
efi_disk {
  datastore_id = var.disk_datastore_id
  file_format  = "raw"  # Required for UEFI boot
  type         = "4m"
}
```

#### 3. Tags Provider Inconsistency

**Error**:
```
Provider produced inconsistent final plan
```

**Root Cause**: Using incorrect tag format (map instead of list)

**Fix**: Change tags variable type from `map(string)` to `list(string)`:

```hcl
variable "tags" {
  description = "Tags to apply to the VM (list of strings)"
  type        = list(string)
  default     = []
}
```

**Reference**: Correct format found in [basher83/Hercules-Vault-Infra](https://github.com/basher83/Hercules-Vault-Infra) repository

#### 4. QEMU Guest Agent Timeout

**Issue**: qemu-guest-agent not initializing via cloud-init vendor_data

**Attempted Fix**: Created vendor_data snippet to install qemu-guest-agent:

```hcl
resource "proxmox_virtual_environment_file" "vendor_data" {
  count = var.cloud_init_enabled ? 1 : 0

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    file_name = "microk8s-vendor-${var.vm_id}.yaml"
    data      = <<-EOF
#cloud-config
packages:
  - qemu-guest-agent

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
    EOF
  }
}
```

**Status**: Not working reliably with cloud-init

**Resolution**: Deferred to Ansible configuration phase (Phase 2) for proper package management

**Reference**: Provider documentation at [bpg/terraform-provider-proxmox](https://github.com/bpg/terraform-provider-proxmox)

### Common Issues

1. **"Invalid template ID"**

   - Verify template VM 7024 exists in Proxmox
   - Check target_node name matches Proxmox node

2. **"Authentication failed"**

   - Verify pve_api_token is valid and not expired
   - Check pve_api_url and ensure API token has proper permissions
   - Verify API token format: "USER@REALM!TOKENID=TOKENVALUE"

3. **"Bridge not found"**

   - Confirm vmbr0 and vmbr1 exist in Proxmox network configuration
   - Update bridge names if using different ones

4. **"Insufficient resources"**
   - Check available RAM (4 VMs × ~4GB = 16GB minimum) - Jumpbox uses 512MB, nodes use 4GB each
   - Verify CPU cores available (4 VMs × ~2 cores = 8 cores minimum) - Jumpbox uses 1 core, nodes use 2 cores each

### Debug Commands

```bash
# Check Proxmox API connectivity
curl -k https://YOUR_PROXMOX_IP:8006/api2/json/version

# Validate terraform syntax
terraform fmt -check

# Refresh Terraform Language Server (fixes IDE linting errors)
terraform init -upgrade && terraform validate

# Check deployed VM state
terraform state list

# View specific VM configuration
terraform state show 'module.vm["microk8s-1"].proxmox_virtual_environment_vm.vm'
```

## Next Steps

- PREP-003: Initialize Terraform and validate Proxmox connectivity
- INFRA-001: Deploy infrastructure with terraform apply

## Resources

- [Terraform Proxmox Provider Documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [SSH Key Generation Guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key)
- [Proxmox Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration)
