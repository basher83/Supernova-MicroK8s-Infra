# Proxmox VM Provisioning Guide

## Executive Summary

This guide analyzes VM provisioning approaches using the `bpg/proxmox` Terraform provider, provides concise examples for single VM and 3-VM cluster deployments, and offers recommendations for module architecture.

**Key Finding**: The **Template-Clone** approach offers the best balance of speed, flexibility, and resource efficiency for homelab deployments, especially for clusters.

---

## Table of Contents

- [Provisioning Approaches](#provisioning-approaches)
- [Single VM Examples](#single-vm-examples)
- [3-VM Cluster Examples](#3-vm-cluster-examples)
- [Pros & Cons Comparison](#pros--cons-comparison)
- [Module Architecture Recommendations](#module-architecture-recommendations)
- [Best Practices](#best-practices)

---

## Provisioning Approaches

The `bpg/proxmox` provider supports three primary VM provisioning approaches:

### 1. Template-Clone (Two-Step)

Creates a VM template from a cloud image, then clones VMs from that template.

**Resources used:**
- `proxmox_virtual_environment_download_file` (downloads cloud image once)
- `proxmox_virtual_environment_vm` (template with `template = true`)
- `proxmox_virtual_environment_vm` (clone with `clone {}` block)

### 2. Direct Import (Cloud Image)

Downloads and directly imports a cloud image as the VM's disk.

**Resources used:**
- `proxmox_virtual_environment_download_file` (downloads per VM)
- `proxmox_virtual_environment_vm` (with `disk { import_from }`)

### 3. Existing Template Clone (Single-Step)

Clones from a pre-existing template (created manually or via separate Terraform).

**Resources used:**
- `proxmox_virtual_environment_vm` (clone with `clone {}` block)

---

## Single VM Examples

### Approach 1: Template-Clone (Two-Step)

**Best for**: Testing template configuration, first-time setup

```hcl
# Step 1: Download cloud image
resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

# Step 2: Create template VM
resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name         = "ubuntu-22-04-template"
  node_name    = "pve"
  template     = true
  started      = false

  machine      = "q35"
  bios         = "ovmf"

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  efi_disk {
    datastore_id = "local-lvm"
    type         = "4m"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }
}

# Cloud-init configuration
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ubuntu-template
    users:
      - default
      - name: ubuntu
        groups: [sudo]
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(file("~/.ssh/id_rsa.pub"))}
        sudo: ALL=(ALL) NOPASSWD:ALL
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
    EOF
    file_name = "cloud-init-ubuntu.yaml"
  }
}

# Step 3: Clone from template
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name      = "ubuntu-vm-01"
  node_name = "pve"

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template.id
  }

  agent {
    enabled = true
  }

  memory {
    dedicated = 4096
  }

  initialization {
    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
    ip_config {
      ipv4 {
        address = "192.168.1.100/24"
        gateway = "192.168.1.1"
      }
    }
  }
}
```

### Approach 2: Direct Import (Cloud Image)

**Best for**: One-off VMs, testing

```hcl
resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  file_name    = "jammy-server-cloudimg-amd64.qcow2"  # Must specify .qcow2 extension
}

resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name      = "ubuntu-vm-01"
  node_name = "pve"

  stop_on_destroy = true  # Required when qemu-guest-agent not installed

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.100/24"
        gateway = "192.168.1.1"
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(file("~/.ssh/id_rsa.pub"))]
    }
  }
}
```

### Approach 3: Existing Template Clone

**Best for**: Production deployments, multiple VMs

```hcl
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name      = "ubuntu-vm-01"
  node_name = "pve"

  clone {
    vm_id = 2000  # Pre-existing template VM ID
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 32  # Can resize from template
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    dns {
      servers = ["1.1.1.1"]
    }
    ip_config {
      ipv4 {
        address = "192.168.1.100/24"
        gateway = "192.168.1.1"
      }
    }
  }
}
```

---

## 3-VM Cluster Examples

### Approach 1: Template-Clone with `count`

**Best for**: Identical VMs with sequential naming/IPs

```hcl
# Template creation (same as single VM example)
resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  # ... (see single VM example above)
}

# Clone 3 VMs from template
resource "proxmox_virtual_environment_vm" "k8s_cluster" {
  count     = 3
  name      = "k8s-node-${count.index + 1}"
  node_name = "pve"

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template.id
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 4
  }

  memory {
    dedicated = 8192
  }

  initialization {
    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
    ip_config {
      ipv4 {
        address = "192.168.1.${100 + count.index}/24"
        gateway = "192.168.1.1"
      }
    }
  }
}

output "cluster_ips" {
  value = [for vm in proxmox_virtual_environment_vm.k8s_cluster : vm.ipv4_addresses[1][0]]
}
```

### Approach 2: Template-Clone with `for_each` (Named Nodes)

**Best for**: Different configurations per node, named servers

```hcl
locals {
  cluster_nodes = {
    "k8s-master" = {
      ip     = "192.168.1.100"
      cores  = 4
      memory = 8192
      node   = "pve1"  # Can distribute across nodes
    }
    "k8s-worker-1" = {
      ip     = "192.168.1.101"
      cores  = 4
      memory = 16384
      node   = "pve2"
    }
    "k8s-worker-2" = {
      ip     = "192.168.1.102"
      cores  = 4
      memory = 16384
      node   = "pve3"
    }
  }
}

resource "proxmox_virtual_environment_vm" "k8s_cluster" {
  for_each  = local.cluster_nodes
  name      = each.key
  node_name = each.value.node

  clone {
    vm_id = 2000  # Pre-existing template
  }

  agent {
    enabled = true
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  initialization {
    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "192.168.1.1"
      }
    }
  }
}

output "cluster_nodes" {
  value = {
    for name, vm in proxmox_virtual_environment_vm.k8s_cluster :
    name => vm.ipv4_addresses[1][0]
  }
}
```

### Approach 3: Direct Import (Not Recommended for Clusters)

**Note**: This approach downloads the image 3 times - inefficient for clusters.

```hcl
variable "cluster_count" {
  default = 3
}

resource "proxmox_virtual_environment_download_file" "ubuntu_images" {
  count        = var.cluster_count
  content_type = "import"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  file_name    = "jammy-server-cloudimg-amd64-${count.index}.qcow2"
}

resource "proxmox_virtual_environment_vm" "k8s_cluster" {
  count     = var.cluster_count
  name      = "k8s-node-${count.index + 1}"
  node_name = "pve"

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.ubuntu_images[count.index].id
    interface    = "virtio0"
    size         = 20
  }

  # ... rest of configuration
}
```

---

## Pros & Cons Comparison

### Template-Clone (Two-Step)

**Pros:**
- ✅ **Fast deployment**: Cloning is significantly faster than importing images (seconds vs minutes)
- ✅ **Resource efficient**: Cloud image downloaded once, shared across all clones
- ✅ **Consistent base**: All VMs start from identical template
- ✅ **Flexible customization**: Can resize disks, modify CPU/RAM per clone
- ✅ **Best for clusters**: Ideal for deploying multiple identical VMs
- ✅ **Template versioning**: Can maintain multiple template versions
- ✅ **Smaller Terraform state**: Cloud image download happens once

**Cons:**
- ❌ **Two-step process**: Must create template first
- ❌ **Template maintenance**: Need to update/rebuild templates for base image changes
- ❌ **Additional resource**: Template VM consumes storage (minimal)
- ❌ **Initial complexity**: Requires understanding of template workflow

**Best For:**
- Production clusters (3+ VMs)
- Rapid scaling scenarios
- Standardized VM deployments
- MicroK8s/K8s clusters

---

### Direct Import (Cloud Image)

**Pros:**
- ✅ **Simple workflow**: One-step process, no template needed
- ✅ **Always fresh**: Downloads latest cloud image each time
- ✅ **No template management**: Less infrastructure to maintain
- ✅ **Self-contained**: Each VM completely independent
- ✅ **Good for testing**: Quick ad-hoc VM creation

**Cons:**
- ❌ **Slow deployment**: Downloads image for each VM (~200MB per VM)
- ❌ **Network intensive**: Repeated downloads consume bandwidth
- ❌ **Storage inefficient**: Duplicate image files in Proxmox storage
- ❌ **Longer apply time**: Each `terraform apply` takes minutes
- ❌ **Not scalable**: Terrible for clusters (3 VMs = 3 downloads)
- ❌ **Larger state file**: Multiple download resources

**Best For:**
- Single VM deployments
- Testing/development
- One-off VMs
- Learning/experimentation

---

### Existing Template Clone (Single-Step)

**Pros:**
- ✅ **Fastest deployment**: Clones from pre-existing template
- ✅ **Simplest Terraform**: Minimal configuration required
- ✅ **No download time**: Template already exists
- ✅ **Production ready**: Separates template management from VM deployment
- ✅ **GitOps friendly**: VM configuration separate from template
- ✅ **Most scalable**: Perfect for clusters of any size

**Cons:**
- ❌ **External dependency**: Requires pre-existing template (manual or separate TF)
- ❌ **Template ID coupling**: Must know/reference template VM ID
- ❌ **No template versioning**: Harder to track template changes
- ❌ **Coordination required**: Template updates require separate workflow

**Best For:**
- Production deployments
- Large-scale clusters
- Teams with dedicated template management
- CI/CD pipelines
- Enterprise environments

---

## Module Architecture Recommendations

### Recommended Structure: Hybrid Approach

Based on analysis of provider capabilities and your existing modules, here's the recommended architecture:

```
terraform/
├── modules/
│   ├── vm/                      # ⭐ Unified VM module (KEEP & ENHANCE)
│   │   ├── main.tf              # Supports both clone & direct import via vm_type
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vm-cluster/              # 🆕 NEW: Cluster-specific wrapper
│   │   ├── main.tf              # Uses vm/ module with count/for_each
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── image/                   # KEEP: Cloud image download
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── deployments/
    ├── templates/               # 🆕 NEW: Template management
    │   └── ubuntu-22-04/
    │       ├── main.tf
    │       └── variables.tf
    │
    └── prod/
        ├── k8s-cluster/         # Uses vm-cluster module
        │   ├── main.tf
        │   └── terraform.tfvars
        └── single-vm/           # Uses vm module directly
            ├── main.tf
            └── terraform.tfvars
```

### Module Recommendations

#### 1. Keep `vm/` Module (Current Implementation)

Your existing `vm/` module is excellent. It already supports:
- ✅ Both `clone` and `image` types via `vm_type` variable
- ✅ Flexible disk configuration
- ✅ Dynamic blocks for optional features
- ✅ Proper lifecycle management

**Recommended Enhancement:**

```hcl
# modules/vm/variables.tf
variable "vm_type" {
  description = "VM creation type: 'clone' or 'image'"
  type        = string
  validation {
    condition     = contains(["clone", "image"], var.vm_type)
    error_message = "vm_type must be 'clone' or 'image'"
  }
}

# Add optional template_id for external templates
variable "template_id" {
  description = "Template VM ID for clone type (optional, uses src_clone.tpl_id if not specified)"
  type        = number
  default     = null
}
```

#### 2. Create `vm-cluster/` Module (NEW)

Wrapper module for cluster deployments.

```hcl
# modules/vm-cluster/main.tf
module "cluster_vms" {
  source   = "../vm"
  for_each = var.nodes

  vm_type  = "clone"
  pve_node = each.value.pve_node
  vm_name  = each.key

  src_clone = {
    datastore_id = var.template_datastore
    tpl_id       = var.template_id
  }

  vm_cpu = {
    cores = each.value.cpu_cores
    type  = var.cpu_type
  }

  vm_mem = {
    dedicated = each.value.memory
  }

  vm_disk = {
    scsi0 = {
      datastore_id = each.value.disk_datastore
      size         = each.value.disk_size
      main_disk    = true
    }
  }

  vm_net_ifaces = {
    net0 = {
      bridge    = var.network_bridge
      ipv4_addr = "${each.value.ip_address}/${var.network_cidr}"
      ipv4_gw   = var.network_gateway
    }
  }

  vm_init = var.cloud_init_config
}

output "cluster_ips" {
  value = { for name, vm in module.cluster_vms : name => vm.ip_address }
}
```

```hcl
# modules/vm-cluster/variables.tf
variable "nodes" {
  description = "Map of cluster nodes with their configuration"
  type = map(object({
    pve_node       = string
    ip_address     = string
    cpu_cores      = number
    memory         = number
    disk_datastore = string
    disk_size      = number
  }))
}

variable "template_id" {
  description = "VM template ID to clone from"
  type        = number
}

variable "template_datastore" {
  description = "Datastore where template resides"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge for all nodes"
  type        = string
  default     = "vmbr0"
}

variable "network_cidr" {
  description = "Network CIDR suffix (e.g., '24')"
  type        = string
}

variable "network_gateway" {
  description = "Network gateway IP"
  type        = string
}

variable "cpu_type" {
  description = "CPU type for all nodes"
  type        = string
  default     = "host"
}

variable "cloud_init_config" {
  description = "Cloud-init configuration"
  type        = any
}
```

#### 3. Example Deployment: MicroK8s Cluster

```hcl
# deployments/prod/microk8s-cluster/main.tf
module "microk8s_cluster" {
  source = "../../../modules/vm-cluster"

  template_id        = 2000
  template_datastore = "local-lvm"
  network_bridge     = "vmbr0"
  network_cidr       = "24"
  network_gateway    = "192.168.1.1"

  nodes = {
    "microk8s-1" = {
      pve_node       = "pve1"
      ip_address     = "192.168.1.101"
      cpu_cores      = 4
      memory         = 8192
      disk_datastore = "local-lvm"
      disk_size      = 50
    }
    "microk8s-2" = {
      pve_node       = "pve2"
      ip_address     = "192.168.1.102"
      cpu_cores      = 4
      memory         = 8192
      disk_datastore = "local-lvm"
      disk_size      = 50
    }
    "microk8s-3" = {
      pve_node       = "pve3"
      ip_address     = "192.168.1.103"
      cpu_cores      = 4
      memory         = 8192
      disk_datastore = "local-lvm"
      disk_size      = 50
    }
  }

  cloud_init_config = {
    datastore_id = "local"
    interface    = "ide0"
    dns = {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }
}

output "microk8s_node_ips" {
  value = module.microk8s_cluster.cluster_ips
}
```

### Alternative: Simpler Approach (No Wrapper Module)

If you prefer maximum simplicity, use the existing `vm/` module directly with `for_each`:

```hcl
# deployments/prod/microk8s-cluster/main.tf
locals {
  microk8s_nodes = {
    "microk8s-1" = { node = "pve1", ip = "192.168.1.101" }
    "microk8s-2" = { node = "pve2", ip = "192.168.1.102" }
    "microk8s-3" = { node = "pve3", ip = "192.168.1.103" }
  }
}

module "microk8s_vms" {
  source   = "../../../modules/vm"
  for_each = local.microk8s_nodes

  vm_type  = "clone"
  pve_node = each.value.node
  vm_name  = each.key

  src_clone = {
    datastore_id = "local-lvm"
    tpl_id       = 2000
  }

  vm_cpu = {
    cores = 4
    type  = "host"
  }

  vm_mem = {
    dedicated = 8192
  }

  vm_disk = {
    scsi0 = {
      datastore_id = "local-lvm"
      size         = 50
      main_disk    = true
    }
  }

  vm_net_ifaces = {
    net0 = {
      bridge    = "vmbr0"
      ipv4_addr = "${each.value.ip}/24"
      ipv4_gw   = "192.168.1.1"
    }
  }

  vm_init = {
    datastore_id = "local"
    interface    = "ide0"
  }
}
```

---

## Best Practices

### 1. Template Management

**Separate template creation from VM deployment:**

```
# Option A: Manual template creation (recommended for homelab)
1. Create template via Proxmox UI or Ansible
2. Reference template ID in Terraform

# Option B: Separate Terraform workspace
terraform/deployments/templates/ubuntu-22-04/
  - Creates and maintains template
  - Rare updates (quarterly or as needed)

terraform/deployments/prod/my-cluster/
  - References template ID
  - Frequent updates for VM changes
```

### 2. Cloud-Init Best Practices

**Use custom cloud-init for production:**

```hcl
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.pve_node

  source_raw {
    data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      hostname    = var.hostname
      ssh_keys    = var.ssh_public_keys
      timezone    = var.timezone
      nameservers = var.dns_servers
    })
    file_name = "${var.hostname}-cloud-init.yaml"
  }
}
```

### 3. Use Lifecycle Rules

```hcl
lifecycle {
  # Prevent accidental destruction
  prevent_destroy = true

  # Ignore cloud-init changes (prevents forced replacement)
  ignore_changes = [
    initialization["user_account"],
  ]

  # Create new VM before destroying old (blue-green)
  create_before_destroy = true
}
```

### 4. Resource Dependencies

```hcl
# Explicit dependency when needed
depends_on = [
  proxmox_virtual_environment_vm.template
]

# Use module outputs for implicit dependencies
clone {
  vm_id = module.template.vm_id  # Cleaner than explicit depends_on
}
```

### 5. Variable Validation

```hcl
variable "vm_type" {
  type = string
  validation {
    condition     = contains(["clone", "image"], var.vm_type)
    error_message = "vm_type must be 'clone' or 'image'"
  }
}

variable "ip_address" {
  type = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.ip_address))
    error_message = "ip_address must be in CIDR notation (e.g., 192.168.1.100/24)"
  }
}
```

---

## Summary

### For Single VMs

**Recommendation**: Use **Existing Template Clone** approach
- Fastest deployment
- Simplest Terraform code
- Most reliable

### For 3-VM Clusters

**Recommendation**: Use **Existing Template Clone** with `for_each`
- Fastest cluster deployment (seconds not minutes)
- Resource efficient (one template, three clones)
- Named nodes (better than count)
- Per-node customization

### Module Architecture

**Recommendation**: Keep it simple
1. **Keep current `vm/` module** - already excellent
2. **Optional**: Add `vm-cluster/` wrapper for DRY cluster configs
3. **Templates**: Manage separately (Ansible/manual/separate TF)

### Key Principles

- ✅ **DRY**: Reuse the `vm/` module, don't duplicate
- ✅ **Simple**: Avoid over-engineering, prefer flat structure
- ✅ **Fast**: Use template-clone for clusters
- ✅ **Flexible**: `for_each` over `count` for named resources
- ✅ **Maintainable**: Separate concerns (template vs VM deployment)

---

**Provider Version**: `bpg/proxmox >= 0.84.1`
**Terraform Version**: `>= 1.5.0`
**Analysis Date**: 2025-10-08
