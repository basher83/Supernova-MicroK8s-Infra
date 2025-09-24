---
Task: Create Terraform module for MicroK8s master nodes with HA configuration
Task ID: TER-003
Priority: P0
Estimated Time: 3 hours
Dependencies: TER-002
Status: ⏸️ Blocked
Created: 2025-09-20
Updated: 2025-09-20
---

## Objective

Develop a comprehensive Terraform module for MicroK8s master nodes that supports HA configuration, proper resource allocation, and integrates vendor data for automated setup.

## Prerequisites

- [ ] TER-002 completed (vendor data templates ready)
- [ ] Understanding of Proxmox Terraform provider
- [ ] Knowledge of MicroK8s HA requirements
- [ ] Access to existing `infrastructure/modules/vm/` for patterns

## Implementation Steps

### 1. **Create Module Structure**

Create `infrastructure-microk8s/modules/microk8s-master/variables.tf`:

```hcl
variable "vm_name" {
  type        = string
  description = "Name of the master node VM"
}

variable "vm_id" {
  type        = number
  description = "Proxmox VM ID"
}

variable "vm_node_name" {
  type        = string
  description = "Proxmox cluster node to deploy on"
}

variable "vcpu" {
  type        = number
  description = "Number of vCPUs"
  default     = 4
}

variable "vcpu_type" {
  type        = string
  description = "CPU type (host, kvm64, etc)"
  default     = "host"
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 8192
}

variable "disk_size" {
  type        = number
  description = "Root disk size in GB"
  default     = 60
}

variable "vm_ip_primary" {
  type        = string
  description = "Primary IP address with CIDR notation"
}

variable "vm_gateway" {
  type        = string
  description = "Gateway IP address"
}

variable "vm_bridge_1" {
  type        = string
  description = "Primary network bridge"
  default     = "vmbr0"
}

variable "template_id" {
  type        = number
  description = "Template VM ID to clone from"
}

variable "datastore_id" {
  type        = string
  description = "Proxmox datastore for VM disk"
  default     = "local-lvm"
}

variable "microk8s_version" {
  type        = string
  description = "MicroK8s version to install"
  default     = "1.28"
}

variable "microk8s_channel" {
  type        = string
  description = "MicroK8s snap channel"
  default     = "1.28/stable"
}

variable "cluster_token" {
  type        = string
  description = "Token for cluster joining"
  sensitive   = true
}

variable "is_primary_master" {
  type        = bool
  description = "Is this the primary master node"
  default     = false
}

variable "enable_ha" {
  type        = bool
  description = "Enable HA configuration"
  default     = true
}

variable "ci_ssh_key" {
  type        = string
  description = "SSH public key for access"
}

variable "ssh_username" {
  type        = string
  description = "SSH username"
  default     = "ubuntu"
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for the VM"
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "vm_tags" {
  type        = list(string)
  description = "Tags to apply to the VM"
  default     = ["microk8s", "master"]
}
```

### 2. **Create Main Module Configuration**

Create `infrastructure-microk8s/modules/microk8s-master/main.tf`:

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.73.2"
    }
  }
}

# Create vendor data snippet for cloud-init
resource "proxmox_virtual_environment_file" "vendor_data" {
  content_type = "snippets"
  datastore_id = var.datastore_id
  node_name    = var.vm_node_name

  source_raw {
    file_name = "${var.vm_name}-vendor.yaml"
    data = templatefile("${path.module}/../../vendor-data/microk8s-master.yaml", {
      microk8s_channel  = var.microk8s_channel
      ssh_username      = var.ssh_username
      cluster_token     = var.cluster_token
      is_primary_master = var.is_primary_master
      ha_enabled        = var.enable_ha
      failure_domain    = var.vm_node_name
      dns_server        = var.dns_servers[0]
    })
  }
}

# Create the master VM
resource "proxmox_virtual_environment_vm" "master" {
  name        = var.vm_name
  vm_id       = var.vm_id
  node_name   = var.vm_node_name
  description = "MicroK8s Master Node - ${var.vm_name}"
  tags        = var.vm_tags

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.vcpu
    type  = var.vcpu_type
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
    interface    = "virtio0"
  }

  network_device {
    bridge = var.vm_bridge_1
  }

  operating_system {
    type = "l26" # Linux 2.6+
  }

  initialization {
    ip_config {
      ipv4 {
        address = var.vm_ip_primary
        gateway = var.vm_gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_data_file_id = proxmox_virtual_environment_file.vendor_data.id

    user_account {
      username = var.ssh_username
      keys     = [trimspace(var.ci_ssh_key)]
    }
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_account[0].keys,
    ]
  }

  startup {
    order      = var.is_primary_master ? "1" : "2"
    up_delay   = var.is_primary_master ? 0 : 30
    down_delay = 10
  }
}
```

### 3. **Create Module Outputs**

Create `infrastructure-microk8s/modules/microk8s-master/outputs.tf`:

```hcl
output "vm_id" {
  value       = proxmox_virtual_environment_vm.master.vm_id
  description = "VM ID in Proxmox"
}

output "vm_name" {
  value       = proxmox_virtual_environment_vm.master.name
  description = "VM name"
}

output "ip_address" {
  value       = trimprefix(var.vm_ip_primary, "")
  description = "IP address of the master node"
}

output "node_info" {
  value = {
    name    = var.vm_name
    id      = var.vm_id
    ip      = split("/", var.vm_ip_primary)[0]
    node    = var.vm_node_name
    role    = "master"
    primary = var.is_primary_master
  }
  description = "Complete node information"
}
```

### 4. **Create Example Usage**

Create `infrastructure-microk8s/modules/microk8s-master/examples/main.tf`:

```hcl
# Example usage of the microk8s-master module

module "master_nodes" {
  count  = 3
  source = "../"

  vm_name      = "k8s-master-${count.index + 1}"
  vm_id        = 3100 + count.index
  vm_node_name = element(["proxmox-1", "proxmox-2", "proxmox-3"], count.index)

  vcpu      = 4
  memory    = 8192
  disk_size = 60

  vm_ip_primary = "192.168.10.${10 + count.index}/24"
  vm_gateway    = "192.168.10.1"

  template_id       = var.template_id
  microk8s_version  = "1.28"
  cluster_token     = random_password.cluster_token.result
  is_primary_master = count.index == 0
  enable_ha         = true

  ci_ssh_key = file("~/.ssh/id_rsa.pub")

  vm_tags = ["microk8s", "master", "production"]
}

resource "random_password" "cluster_token" {
  length  = 32
  special = false
}
```

## Success Criteria

- [ ] Module properly creates master VMs in Proxmox
- [ ] Vendor data correctly applied via cloud-init
- [ ] HA configuration supported for multi-master setup
- [ ] Primary master detection and configuration
- [ ] Proper resource allocation based on variables
- [ ] Module is reusable across environments

## Validation

```bash
# Validate module syntax
cd infrastructure-microk8s/modules/microk8s-master
terraform init
terraform validate

# Test module with example
cd examples/
terraform plan

# Check module documentation
terraform-docs markdown . > README.md

# Lint the module
tflint .
```

Expected output:
- Module validates without errors
- Example plan shows correct resources
- Documentation generated successfully
- No critical lint issues

## Notes

- Use lifecycle rules to prevent accidental SSH key changes
- Set startup order for proper cluster initialization
- Consider adding validation rules for variable inputs
- Test with both single and multi-master configurations
- Ensure compatibility with existing Proxmox setup

## References

- [Proxmox Provider Documentation](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- Existing module patterns in `infrastructure/modules/vm/`
- [MicroK8s HA Documentation](https://microk8s.io/docs/high-availability)
- [Planning Document](../../docs/planning.md) - Terraform Module Design section