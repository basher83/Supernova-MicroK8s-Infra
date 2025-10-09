# Troubleshooting: Terraform VM Modules

This guide covers common issues when working with the `vm/` and `vm-cluster/` Terraform modules.

## Table of Contents

- [Network Configuration Issues](#network-configuration-issues)
- [Variable Type Issues](#variable-type-issues)
- [Module Caching Issues](#module-caching-issues)
- [Cross-Node Cloning Issues](#cross-node-cloning-issues)
  - [Error: Template Not Found on Target Node (try() Bug)](#error-template-not-found-on-target-node-try-bug) ⚠️ **Critical**
- [Cloud-init Issues](#cloud-init-issues)
- [Validation Errors](#validation-errors)
- [Critical Bug: try() with optional() Fields](#critical-bug-try-with-optional-fields)

---

## Network Configuration Issues

### VLAN ID Shows as 0 or NULL in Plan

**Symptoms:**
```
+ network_device {
    + bridge   = "vmbr0"
    + vlan_id  = 0        # Should be 2
}
```

**Common Causes:**

1. **Variable Type Mismatch**: VLAN ID defined as string instead of number

```hcl
# ❌ WRONG
vlan_id_secondary = "2"

# ✅ CORRECT
vlan_id_secondary = 2
```

**Fix:** Update `terraform.tfvars` to use number type:
```hcl
vlan_id           = 30
vlan_id_secondary = 2
```

2. **Optional Field with try() Function**: The `vm-cluster` module used `try()` with optional fields

The issue was in `terraform/modules/vm-cluster/main.tf` (fixed in recent commits):

```hcl
# ❌ WRONG - try() treats null as valid value
vlan_id = try(each.value.vlan_id, net_config.vlan_id, null)

# ✅ CORRECT - explicit null check
vlan_id = each.value.vlan_id != null ? each.value.vlan_id : net_config.vlan_id
```

**Diagnosis Commands:**
```bash
# Check variable values
tofu console <<EOF
var.vlan_id_secondary
var.network_bridge_secondary
EOF

# Check computed local values (if using locals)
tofu console <<EOF
local.network_interfaces
EOF

# Check plan output
tofu plan -no-color 2>&1 | grep -A 20 "network_device"
```

---

### Secondary NIC Not Created or Wrong Configuration

**Symptoms:**
- Second network interface always created even when `enable_secondary_nic = false`
- Secondary NIC has wrong bridge or VLAN

**Common Causes:**

1. **Incorrect Conditional Logic**: Using ternary for IP address instead of conditionally creating the NIC

```hcl
# ❌ WRONG - net1 always created
vm_net_ifaces = {
  net0 = { ... }
  net1 = {
    ipv4_addr = var.enable_secondary_nic ? "..." : "dhcp"
  }
}

# ✅ CORRECT - conditionally create net1
vm_net_ifaces = merge(
  {
    net0 = { ... }
  },
  var.enable_secondary_nic ? {
    net1 = { ... }
  } : {}
)
```

2. **Missing VLAN ID Parameter**: Secondary NIC defined without `vlan_id` field

```hcl
# ❌ WRONG - missing vlan_id
net1 = {
  bridge  = var.network_bridge_secondary
  # vlan_id missing
}

# ✅ CORRECT - includes vlan_id
net1 = {
  bridge  = var.network_bridge_secondary
  vlan_id = var.vlan_id_secondary
}
```

**Fix Pattern for Single VM Deployments:**

`main.tf`:
```hcl
vm_net_ifaces = merge(
  {
    net0 = {
      bridge    = var.network_bridge
      vlan_id   = var.vlan_id
      firewall  = false
      ipv4_addr = "${var.ip_address}/${var.network_cidr}"
      ipv4_gw   = var.network_gateway
    }
  },
  var.enable_secondary_nic ? {
    net1 = {
      bridge    = var.network_bridge_secondary
      vlan_id   = var.vlan_id_secondary
      firewall  = false
      ipv4_addr = "${var.ip_address_secondary}/${var.network_cidr_secondary}"
      ipv4_gw   = null
    }
  } : {}
)
```

**Fix Pattern for Cluster Deployments:**

`main.tf`:
```hcl
locals {
  network_interfaces = merge(
    {
      net0 = {
        bridge     = var.network_bridge
        vlan_id    = var.vlan_id
        firewall   = false
        model      = "virtio"
        mtu        = 1500
        rate_limit = null
      }
    },
    var.enable_secondary_nic ? {
      net1 = {
        bridge     = var.network_bridge_secondary
        vlan_id    = var.vlan_id_secondary
        firewall   = false
        model      = "virtio"
        mtu        = 1500
        rate_limit = null
      }
    } : {}
  )
}

module "microk8s_cluster" {
  source = "../../../modules/vm-cluster"

  network_interfaces = local.network_interfaces
  # ...
}
```

---

## Variable Type Issues

### Error: Invalid value for input variable

**Symptoms:**
```
Error: Invalid value for input variable
on variables.tf line 104:
  104: variable "vlan_id_secondary" {

The given value is not suitable for var.vlan_id_secondary declared at
variables.tf:104,1-33: number required.
```

**Common Causes:**

1. **String Instead of Number**: Variable defined as number but provided as string

```hcl
# variables.tf
variable "vlan_id" {
  type = number  # Expects number
}

# terraform.tfvars
# ❌ WRONG
vlan_id = "30"

# ✅ CORRECT
vlan_id = 30
```

2. **List Instead of String**: Accidentally providing list syntax

```hcl
# ❌ WRONG
ssh_public_keys = "ssh-ed25519 AAAA..."

# ✅ CORRECT
ssh_public_keys = [
  "ssh-ed25519 AAAA..."
]
```

**Fix:** Check variable type definitions in `variables.tf` and ensure `terraform.tfvars` matches:

| Variable Type | Correct Syntax | Wrong Syntax |
|--------------|----------------|--------------|
| `string` | `"value"` | `value` (unquoted) |
| `number` | `42` | `"42"` |
| `bool` | `true` | `"true"` |
| `list(string)` | `["a", "b"]` | `"a, b"` |

---

## Module Caching Issues

### Module Changes Not Applied

**Symptoms:**
- Made changes to module files but plan shows old values
- Network interfaces or other configuration seems "stuck"

**Solution:**

```bash
# 1. Reinitialize modules
tofu init -upgrade

# 2. If that doesn't work, clear module cache
rm -rf .terraform/modules
tofu init

# 3. For persistent issues, clear entire .terraform directory
rm -rf .terraform .terraform.lock.hcl
tofu init
```

**Prevention:**
- Always run `tofu init -upgrade` after pulling module changes
- Use `tofu plan` before `tofu apply` to verify changes

---

## Cross-Node Cloning Issues

### Error: Template Not Found

**Symptoms:**
```
Error: error creating VM: error cloning VM template 2000: error cloning VM template 2000 to node holly: VM 2000 not found
```

**Common Causes:**

1. **Template Exists on Different Node**: Template lives on `lloyd` but trying to clone without specifying source

```hcl
# ❌ WRONG - assumes template on same node as target
module "vm" {
  pve_node = "holly"  # Target node
  # Missing: template_node
}

# ✅ CORRECT - specify template source node
module "vm_cluster" {
  template_node = "lloyd"  # Source node where template lives

  nodes = {
    "vm-1" = {
      pve_node = "holly"  # Target node
    }
  }
}
```

2. **Template ID Incorrect**: Template doesn't exist with specified ID

**Diagnosis Commands:**
```bash
# List templates on Proxmox node
ssh root@proxmox-node "qm list | grep template"

# Check template ID exists on specific node
ssh root@lloyd "qm config 2006 | grep template"

# Verify template is marked as template (not regular VM)
ssh root@lloyd "qm config 2006 | grep -E '(template|name)'"
```

**Fix:**
```hcl
# For vm-cluster module
module "microk8s_cluster" {
  template_id   = 2006          # Correct template ID
  template_node = "lloyd"       # Node where template lives

  nodes = {
    "vm-1" = { pve_node = "holly" }   # Clone to holly
    "vm-2" = { pve_node = "mable" }   # Clone to mable
    "vm-3" = { pve_node = "lloyd" }   # Clone to lloyd
  }
}
```

---

### Cross-Node Cloning Very Slow

**Symptoms:**
- Cloning takes 10+ minutes
- Network traffic high during clone operation

**Explanation:**
Cross-node cloning transfers the entire VM disk over the network between Proxmox nodes. This is expected behavior.

**Solutions:**

1. **Same-Node Cloning**: Clone and deploy to same node for fastest performance
2. **Template Replication**: Create template copies on each node
3. **Network Optimization**: Ensure Proxmox nodes have fast network interconnect (10GbE recommended)

```bash
# Copy template to other nodes (one-time operation)
ssh root@lloyd "qm clone 2006 2006 --target mable --full"
ssh root@lloyd "qm clone 2006 2006 --target holly --full"

# Then use local templates (faster)
module "microk8s_cluster" {
  template_id   = 2006
  # Don't specify template_node - uses local template on each node

  nodes = {
    "vm-1" = { pve_node = "holly" }   # Uses local template
    "vm-2" = { pve_node = "mable" }   # Uses local template
  }
}
```

---

### Error: Template Not Found on Target Node (try() Bug)

**Symptoms:**
```
Error: error waiting for VM clone: All attempts fail:
#1: error cloning VM: received an HTTP 500 response - Reason: unable to find configuration file for VM 2006 on node 'holly'
```

**In the Plan:**
```hcl
+ clone {
    + node_name = "holly"  # ❌ WRONG - should be "lloyd"
    + vm_id     = 2006
}
```

**Root Cause:**

This is a **critical bug** with Terraform/OpenTofu's `try()` function when used with `optional()` fields. When an optional field is `null`, `try(null, fallback)` returns `null` instead of evaluating the fallback.

**The Bug in vm-cluster Module (BEFORE FIX):**

`terraform/modules/vm-cluster/main.tf`:
```hcl
# ❌ WRONG - try() doesn't work with optional fields
src_clone = {
  datastore_id = var.template_datastore
  node_name    = try(each.value.template_node, var.template_node, null)
  tpl_id       = var.template_id
}
```

**What Happens:**
1. `each.value.template_node` is an `optional(string)` field in the nodes object
2. When not provided, its value is `null` (not undefined/missing)
3. `try(null, "lloyd", null)` returns `null` because null is NOT an error
4. The clone operation looks for template on target node instead of source node
5. Template doesn't exist on target node → **Error**

**The Fix (AFTER):**

```hcl
# ✅ CORRECT - explicit null check
src_clone = {
  datastore_id = var.template_datastore
  node_name    = each.value.template_node != null ? each.value.template_node : var.template_node
  tpl_id       = var.template_id
}
```

**Affected Locations in vm-cluster Module:**

This bug affected **11 locations** where optional per-node overrides had fallback values:

1. `template_node` - Cross-node clone source ✅ **Critical**
2. `vm_id` - VM ID assignment
3. `tags` - Additional tags per node
4. `cpu_cores` - CPU override
5. `memory` - Memory override
6. `efi_datastore` - EFI disk location
7. `disk_datastore` - Disk location
8. `disk_size` - Disk size override
9. `user_data_file_id` - Cloud-init override
10. `boot_order` - Startup order
11. `vlan_id` - Network VLAN (also in network_interfaces loop)

**Full Fix Applied:**

All instances replaced with explicit null checks:
```hcl
# CPU configuration
cores = each.value.cpu_cores != null ? each.value.cpu_cores : var.default_cpu_cores

# Memory configuration
dedicated = each.value.memory != null ? each.value.memory : var.default_memory

# Disk configuration
size = each.value.disk_size != null ? each.value.disk_size : disk_config.size

# Network configuration
vlan_id = each.value.vlan_id != null ? each.value.vlan_id : net_config.vlan_id
bridge  = each.value.network_bridge != null ? each.value.network_bridge : net_config.bridge
```

**Diagnosis Commands:**

```bash
# Check what clone configuration is in the plan
tofu plan -no-color 2>&1 | grep -A 6 "clone {"

# Should show:
# + clone {
#     + node_name = "lloyd"   # ✅ Source node
#     + vm_id     = 2006
# }

# Verify template exists on source node
ssh root@lloyd "qm list | grep 2006"

# Check if template is on target node (should fail if cross-node clone needed)
ssh root@holly "qm list | grep 2006"  # Should not exist
```

**Performance Note:**

Cross-node cloning performance (actual deployment times):
- **Local clone** (same node): ~56 seconds
- **Cross-node clone** (lloyd → holly): ~1m29s
- **Cross-node clone** (lloyd → mable): ~1m19s

The slower cross-node cloning is expected as the entire VM disk transfers over the network.

**Key Takeaway:**

🚨 **NEVER use `try()` with `optional()` fields that can be `null`**

```hcl
# ❌ DANGEROUS - try() treats null as valid
value = try(optional_field, fallback)

# ✅ SAFE - explicit null check
value = optional_field != null ? optional_field : fallback
```

**Related Issues:**

- Network VLAN ID showing as 0 instead of configured value
- Secondary NIC always showing primary bridge configuration
- Per-node overrides not working in cluster deployments

All were caused by the same `try()` bug.

---

## Cloud-init Issues

### SSH Keys Not Applied

**Symptoms:**
- Cannot SSH to VM with provided keys
- Cloud-init appears to complete but keys missing

**Common Causes:**

1. **Forced Replacement on SSH Key Change**: This is expected behavior

The `vm` module ignores cloud-init user account changes to prevent forced VM replacement:

```hcl
# In terraform/modules/vm/main.tf
lifecycle {
  ignore_changes = [
    initialization[0].user_account,
  ]
}
```

**Implication:** Changing SSH keys in `terraform.tfvars` won't update existing VMs. This is intentional to prevent VM destruction.

**Fix Options:**

**Option 1**: Accept that SSH key changes don't affect existing VMs (recommended)
- Update keys manually on VMs if needed
- New VMs will get updated keys

**Option 2**: Recreate VM to apply new keys
```bash
# Taint specific VM
tofu taint 'module.single_vm.proxmox_virtual_environment_vm.pve_vm'

# Apply to recreate
tofu apply
```

**Option 3**: Use cloud-init user-data file for dynamic key management
```hcl
vm_user_data = proxmox_virtual_environment_file.user_data.id
```

2. **Validation Error**: SSH keys list empty

```
Error: At least one SSH public key must be provided
```

**Fix:**
```hcl
# variables.tf includes validation
variable "ssh_public_keys" {
  type = list(string)

  validation {
    condition     = length(var.ssh_public_keys) > 0
    error_message = "At least one SSH public key must be provided"
  }
}

# terraform.tfvars must have at least one key
ssh_public_keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFa5HX4E... user@host"
]
```

---

### Cloud-init Datastore Mismatch

**Symptoms:**
```
Error: datastore 'local' not available on node 'holly'
```

**Explanation:**
Cloud-init drive uses directory-based storage (`local`), which may not exist on all nodes.

**Common Datastore Types:**
- `local-lvm`: Block storage for VM disks (available on all nodes)
- `local`: Directory storage for ISOs, snippets, cloud-init (may be node-specific)

**Fix Options:**

**Option 1**: Use shared storage for cloud-init
```hcl
vm_init = {
  datastore_id = "shared-storage"  # Shared across all nodes
  interface    = "ide0"
}
```

**Option 2**: Ensure `local` datastore exists on all nodes
```bash
# On each Proxmox node
pvesm set local --content vztmpl,iso,backup,snippets
```

**Option 3**: Use per-node datastore override in vm-cluster
```hcl
nodes = {
  "vm-1" = {
    pve_node = "holly"
    # Override cloud-init datastore if needed
  }
}
```

---

## Validation Errors

### Error: VM BIOS Type Requires EFI Disk

**Symptoms:**
```
Error: Variable 'vm_efi_disk' is required when using the VM bios type is 'ovmf'
```

**Explanation:**
UEFI boot (`bios = "ovmf"`) requires an EFI disk.

**Fix:**
```hcl
# When using UEFI
vm_bios = "ovmf"

vm_efi_disk = {
  datastore_id = var.datastore
  file_format  = "raw"
  type         = "4m"
}

# When using legacy BIOS
vm_bios = "seabios"
# No EFI disk required
```

---

### Error: Invalid IP Address Format

**Symptoms:**
```
Error: IP address must be a valid IPv4 address without CIDR notation
```

**Common Causes:**

Including CIDR suffix in IP address variable:

```hcl
# ❌ WRONG
ip_address = "192.168.1.100/24"

# ✅ CORRECT
ip_address      = "192.168.1.100"
network_cidr    = "24"
```

The module constructs the full address: `"${var.ip_address}/${var.network_cidr}"`

---

### Error: Template ID Must Be Positive Integer

**Symptoms:**
```
Error: Template ID must be a positive integer
```

**Fix:**
```hcl
# ❌ WRONG
template_id = 0
template_id = -1
template_id = null

# ✅ CORRECT
template_id = 2006
```

---

## Debugging Commands

### General Debugging

```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
tofu plan

# Validate configuration
tofu validate

# Format check
tofu fmt -check -recursive

# Check variable values interactively
tofu console
> var.network_bridge_secondary
> local.network_interfaces
```

### Module-Specific Debugging

```bash
# Show module outputs
tofu output

# Show specific module state
tofu state show 'module.microk8s_cluster.module.cluster_vms["microk8s-1"].proxmox_virtual_environment_vm.pve_vm'

# List all resources
tofu state list

# Show plan in JSON format for analysis
tofu show -json | jq '.planned_values.root_module.child_modules'
```

### Network Configuration Debugging

```bash
# Check network interfaces in plan
tofu plan -no-color 2>&1 | grep -A 20 "network_device"

# Verify VLAN configuration on Proxmox
ssh root@proxmox-node "cat /etc/network/interfaces | grep vmbr"

# Check VM network configuration (after deployment)
ssh root@proxmox-node "qm config <vmid> | grep net"
```

---

## Best Practices

### 1. Always Use Version Control
```bash
git add terraform.tfvars
git commit -m "Update network configuration"
```

### 2. Use terraform.tfvars.example
```bash
# Provide example configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Run Validation Before Apply
```bash
tofu fmt
tofu validate
tofu plan
# Review plan carefully
tofu apply
```

### 4. Use Locals for Complex Logic
```hcl
# Instead of complex inline logic
locals {
  network_interfaces = merge(
    { net0 = { ... } },
    var.enable_secondary_nic ? { net1 = { ... } } : {}
  )
}

module "cluster" {
  network_interfaces = local.network_interfaces
}
```

### 5. Document Non-Obvious Configurations
```hcl
# Dual NIC setup for isolated management network
# net0: Production traffic (VLAN 30)
# net1: Management traffic (VLAN 2)
network_interfaces = merge(...)
```

---

## Getting Help

If you're still experiencing issues:

1. **Check Recent Commits**: Review recent changes to module files
2. **Review Documentation**: See module README files for usage examples
3. **Check Provider Documentation**: [bpg/proxmox provider docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
4. **Enable Debug Logging**: Use `TF_LOG=DEBUG` for detailed output
5. **File Issue**: Create issue with debug logs and configuration

---

## Related Documentation

- [Proxmox VM Provisioning Guide](../terraform/proxmox-vm-provisioning-guide.md)
- [vm Module README](../../terraform/modules/vm/README.md)
- [vm-cluster Module README](../../terraform/modules/vm-cluster/README.md)
- [Ansible Module Parameters](./ansible-module-parameters.md)
- [Proxmox API Delegation](./proxmox-api-delegation.md)

---

**Last Updated:** 2025-01-09
**Terraform Version:** >= 1.0
**OpenTofu Version:** >= 1.6
**Provider:** bpg/proxmox >= 0.84.1

---

## Critical Bug: try() with optional() Fields

**Summary:** The `try()` function treats `null` as a valid value (not an error), causing it to return `null` instead of evaluating fallback arguments when used with `optional()` fields. This affected 11 locations in the vm-cluster module and caused cross-node cloning failures, incorrect VLAN configurations, and per-node override issues.

**Always use:** `field != null ? field : fallback` instead of `try(field, fallback)`
