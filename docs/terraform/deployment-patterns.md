# Terraform Deployment Patterns

Operational patterns for production-grade Proxmox VM deployments. These patterns address infrastructure stability, environment isolation, and operational predictability.

## Pattern 1: Deterministic MAC Addressing

### Purpose

Pin MAC addresses to VMs to prevent drift across Terraform provider updates, preventing breakage of DHCP reservations, firewall rules, and Ansible inventory.

### When to Use

- VMs with static DHCP reservations
- Networks with MAC-based firewall rules
- Environments where MAC changes break automation
- Production clusters requiring stable network identity

### When NOT to Use

- Development environments with no network dependencies
- VMs using purely static IP configuration
- Short-lived test instances

### Implementation

```hcl
locals {
  # Use locally administered MAC range (02:50:00:xx:xx:xx)
  cluster_macs = {
    "vm-1" = { mac1 = "02:50:00:30:01:01", mac2 = "02:50:00:31:01:01" }
    "vm-2" = { mac1 = "02:50:00:30:01:02", mac2 = "02:50:00:31:01:02" }
  }
}

module "cluster_vms" {
  for_each = local.nodes
  source   = "../../modules/vm"

  vm_net_ifaces = {
    net0 = {
      bridge    = "vmbr0"
      mac_addr  = local.cluster_macs[each.key].mac1  # Pin MAC
      ipv4_addr = each.value.ip_address
    }
  }
}
```

**MAC Address Guidelines:**
- Start with `02:` (locally administered, unicast)
- Use consistent scheme: `02:50:00:[VLAN]:[HOST]:[NIC]`
- Document MAC assignments in deployment README

---

## Pattern 2: Environment-Based VM ID Offsets

### Purpose

Prevent VM ID collisions when managing multiple environments (dev/staging/prod) on shared Proxmox infrastructure.

### When to Use

- Multiple environments on same Proxmox cluster
- Separate Terraform workspaces per environment
- Risk of ID conflicts during multi-environment deployments

### When NOT to Use

- Single environment deployments
- Completely isolated Proxmox clusters per environment
- VM IDs explicitly managed elsewhere (e.g., database-driven)

### Implementation

```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

locals {
  # Environment-specific VM ID ranges
  env_offsets = {
    dev     = 2000  # dev: 2000-2999
    staging = 3000  # staging: 3000-3999
    prod    = 4000  # prod: 4000-4999
  }
  vm_id_offset = local.env_offsets[var.environment]

  nodes = {
    "vm-1" = {
      vm_id = local.vm_id_offset + 101  # staging: 3101, prod: 4101
      # ... rest of config
    }
  }
}

module "cluster_vms" {
  for_each = local.nodes
  source   = "../../modules/vm"

  vm_id = each.value.vm_id
  # ... rest of config
}
```

**ID Range Planning:**
- Reserve 1000 IDs per environment
- Document reserved ranges in project README
- Leave gaps for future environments

---

## Pattern 3: Enhanced IP Output with Fallbacks

### Purpose

Provide reliable VM IP addresses in Terraform outputs even when QEMU guest agent is not running, by falling back to configured static IPs.

### When to Use

- VMs with static IP configuration
- Outputs consumed by external automation (Ansible, scripts)
- Deployments where guest agent may not be immediately available

### When NOT to Use

- DHCP-only VMs (no static IP fallback available)
- Environments where guest agent is guaranteed running
- VMs without network configuration

### Implementation

**Module Level** (`terraform/modules/vm/output.tf`):

```hcl
locals {
  # Extract configured IP from first network interface
  configured_primary_ip = try(
    split("/", values(var.vm_net_ifaces)[0].ipv4_addr)[0],
    null
  )

  # Get detected IPs from QEMU guest agent
  detected_ips = try(
    flatten(proxmox_virtual_environment_vm.pve_vm.ipv4_addresses),
    []
  )

  # Filter out localhost and empty addresses
  valid_detected_ips = [
    for ip in local.detected_ips : ip
    if ip != "" && ip != "127.0.0.1" && ip != null
  ]

  detected_primary_ip = length(local.valid_detected_ips) > 0 ? local.valid_detected_ips[0] : null
}

output "primary_ip" {
  description = "Primary IPv4 address (detected via guest agent, falls back to configured IP)"
  value       = coalesce(local.detected_primary_ip, local.configured_primary_ip, "N/A")
}
```

**Deployment Level** (`deployments/.../outputs.tf`):

```hcl
output "cluster_ips" {
  description = "Cluster node IP addresses with fallback to configured IPs"
  value = {
    for name, vm in module.cluster_vms :
    name => vm.primary_ip  # Uses enhanced output from module
  }
}
```

---

## Pattern 4: Per-Node Template Support

### Purpose

Support different VM templates per Proxmox node, useful for heterogeneous hardware or node-specific template versions.

### When to Use

- Proxmox cluster with different CPU architectures (Intel/AMD)
- Nodes with different hardware capabilities (GPU/no-GPU)
- Node-specific template versions during rolling upgrades
- Templates stored locally on each node (not shared storage)

### When NOT to Use

- Homogeneous Proxmox clusters
- Templates stored on shared storage
- No hardware-specific requirements

### Implementation

```hcl
locals {
  # Map Proxmox nodes to their specific templates
  node_templates = {
    "lloyd" = 9101  # Intel CPU template
    "holly" = 9102  # AMD CPU template
    "mable" = 9103  # GPU-enabled template
  }

  nodes = {
    "vm-1" = {
      pve_node = "lloyd"
      # ... other config
    }
    "vm-2" = {
      pve_node = "holly"
      # ... other config
    }
  }
}

module "cluster_vms" {
  for_each = local.nodes
  source   = "../../modules/vm"

  pve_node = each.value.pve_node

  src_clone = {
    datastore_id = "local-lvm"
    node_name    = each.value.pve_node
    tpl_id       = local.node_templates[each.value.pve_node]  # Per-node template
  }

  # ... rest of config
}
```

**Alternative Pattern** (when templates are identical but stored locally):

```hcl
locals {
  # Same template ID across all nodes (cloned locally)
  base_template_id = 9100

  nodes = {
    "vm-1" = { pve_node = "lloyd" }
  }
}

module "cluster_vms" {
  for_each = local.nodes
  source   = "../../modules/vm"

  src_clone = {
    datastore_id = "local-lvm"
    node_name    = each.value.pve_node  # Clone from same node
    tpl_id       = local.base_template_id
  }
}
```

---

## Pattern Combinations

### Production MicroK8s Cluster Example

Combining all patterns for maximum stability:

```hcl
variable "environment" {
  default = "prod"
}

locals {
  env_offsets = { prod = 4000 }
  vm_id_offset = local.env_offsets[var.environment]

  # Deterministic MAC addresses
  cluster_macs = {
    "k8s-1" = { mac1 = "02:50:00:30:01:01", mac2 = "02:50:00:31:01:01" }
    "k8s-2" = { mac1 = "02:50:00:30:01:02", mac2 = "02:50:00:31:01:02" }
    "k8s-3" = { mac1 = "02:50:00:30:01:03", mac2 = "02:50:00:31:01:03" }
  }

  # Per-node templates (if needed)
  node_templates = {
    "lloyd" = 9101
    "holly" = 9102
    "mable" = 9103
  }

  nodes = {
    "k8s-1" = {
      vm_id    = local.vm_id_offset + 101
      pve_node = "lloyd"
      ip       = "192.168.30.101"
    }
    "k8s-2" = {
      vm_id    = local.vm_id_offset + 102
      pve_node = "holly"
      ip       = "192.168.30.102"
    }
    "k8s-3" = {
      vm_id    = local.vm_id_offset + 103
      pve_node = "mable"
      ip       = "192.168.30.103"
    }
  }
}

module "cluster_vms" {
  for_each = local.nodes
  source   = "../../modules/vm"

  vm_name  = each.key
  vm_id    = each.value.vm_id
  pve_node = each.value.pve_node

  src_clone = {
    datastore_id = "local-lvm"
    node_name    = each.value.pve_node
    tpl_id       = local.node_templates[each.value.pve_node]
  }

  vm_net_ifaces = {
    net0 = {
      bridge    = "vmbr0"
      mac_addr  = local.cluster_macs[each.key].mac1
      ipv4_addr = "${each.value.ip}/24"
      ipv4_gw   = "192.168.30.1"
    }
  }
}
```

---

## References

- [Proxmox VM Module](../../terraform/modules/vm/)
- [MicroK8s Cluster Example](../../terraform/deployments/examples/microk8s-cluster/)
- [Proxmox VM Provisioning Guide](./proxmox-vm-provisioning-guide.md)
