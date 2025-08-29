# VM Module

This module provides standardized VM provisioning for Proxmox in the homelab environment.

## Features

- Consistent VM provisioning across environments
- Dual network interfaces (management + application)
- Cloud-init integration for initial configuration
- Tagging for environment and role identification
- Consistent naming convention
- Terraform state management with appropriate lifecycle rules

## Usage

```hcl
module "vm" {
  source = "../../modules/vm"

  // Basic configuration (required)
  vm_name         = "nomad-server-1"
  vm_id           = 3101
  vm_node_name    = "proxmox-node-1"
  vm_ip_primary   = "192.168.10.11/24"
  vm_gateway      = "192.168.10.1"
  vm_ip_secondary = "192.168.11.11/24"

  // Storage configuration
  vm_datastore    = "local-lvm"
  vm_disk_size    = 68  // GB

  // Network configuration
  vm_bridge_1     = "vmbr0"
  vm_bridge_2     = "vmbr1"

  // Compute resources
  vcpu            = 4
  vcpu_type       = "host"
  memory          = 4096  // MB

  // Cloud-init configuration
  cloud_init_username = "ubuntu"
  ci_ssh_key          = "ssh-ed25519 AAAAC3Nz..."

  // Template information
  template_id     = 9101

  // Tagging
  vm_tags         = ["terraform", "nomad", "staging"]
}
```

## Input Variables

| Name                | Description                         | Type         | Required | Default  |
| ------------------- | ----------------------------------- | ------------ | -------- | -------- |
| vm_name             | Name of the VM                      | string       | yes      |          |
| vm_id               | Unique VM ID in Proxmox             | number       | yes      |          |
| vm_node_name        | Proxmox node to place the VM on     | string       | yes      |          |
| vm_ip_primary       | Primary IP address with CIDR        | string       | yes      |          |
| vm_gateway          | Default gateway for primary network | string       | yes      |          |
| vm_ip_secondary     | Secondary IP address with CIDR      | string       | yes      |          |
| vm_datastore        | Storage for VM disk                 | string       | yes      |          |
| vm_disk_size        | Disk size in GB                     | number       | no       | 32       |
| vm_bridge_1         | Primary network bridge              | string       | no       | "vmbr0"  |
| vm_bridge_2         | Secondary network bridge            | string       | no       | "vmbr1"  |
| vcpu                | Number of vCPUs                     | number       | no       | 2        |
| vcpu_type           | CPU type (host, kvm64, etc.)        | string       | no       | "host"   |
| memory              | RAM in MB                           | number       | no       | 2048     |
| cloud_init_username | Username for cloud-init             | string       | no       | "ubuntu" |
| ci_ssh_key          | SSH public key for cloud-init       | string       | yes      |          |
| template_id         | Template VM ID to clone from        | number       | yes      |          |
| vm_tags             | List of tags to apply to the VM     | list(string) | no       | []       |

## Outputs

| Name            | Description                 |
| --------------- | --------------------------- |
| vm_id           | VM ID in Proxmox            |
| vm_name         | VM name                     |
| vm_ip_primary   | Primary IP address          |
| vm_ip_secondary | Secondary IP address        |
| target_node     | Proxmox node hosting the VM |

## Notes

- VMs are created by cloning from a template VM
- Cloud-init is used for initial network and SSH configuration
- VMs have two network interfaces on separate bridges
- Each VM is tagged with its environment and role

## Example in Context

```hcl
locals {
  vm_instances = {
    nomad-server-1 = {
      name    = "nomad-server-1"
      vm_id   = 3101
      ip      = "192.168.10.11/24"
      gateway = "192.168.10.1"
      ip2     = "192.168.11.11/24"
      role    = "server"
    }
    // More VMs...
  }
}

module "vm" {
  for_each = local.vm_instances
  source   = "../../modules/vm"

  vm_name         = each.value.name
  vm_id           = each.value.vm_id
  vm_node_name    = local.node_assignments[each.key].node
  vm_ip_primary   = each.value.ip
  vm_gateway      = each.value.gateway
  vm_ip_secondary = each.value.ip2

  // Common values from variables
  vm_datastore        = var.vm_datastore
  vm_disk_size        = var.vm_disk_size
  vm_bridge_1         = var.vm_bridge_1
  vm_bridge_2         = var.vm_bridge_2
  ci_ssh_key          = var.ci_ssh_key
  template_id         = local.node_assignments[each.key].template_id
  cloud_init_username = var.cloud_init_username

  // Tags
  vm_tags = concat(var.vm_tags, [local.env_tag, each.value.role])
}
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.73.2 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | 0.81.0 |
## Modules

No modules.
## Resources

| Name | Type |
|------|------|
| [proxmox_virtual_environment_vm.vm](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm) | resource |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ci_ssh_key"></a> [ci\_ssh\_key](#input\_ci\_ssh\_key) | SSH public key for cloud-init | `string` | n/a | yes |
| <a name="input_cloud_init_username"></a> [cloud\_init\_username](#input\_cloud\_init\_username) | Username for cloud-init | `string` | `"ubuntu"` | no |
| <a name="input_enable_dual_network"></a> [enable\_dual\_network](#input\_enable\_dual\_network) | Enable dual network configuration with secondary NIC | `bool` | `true` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | RAM in MB | `number` | `2048` | no |
| <a name="input_template_id"></a> [template\_id](#input\_template\_id) | Template VM ID to clone from | `number` | n/a | yes |
| <a name="input_vcpu"></a> [vcpu](#input\_vcpu) | Number of vCPUs | `number` | `2` | no |
| <a name="input_vcpu_type"></a> [vcpu\_type](#input\_vcpu\_type) | CPU type (host, kvm64, etc.) | `string` | `"host"` | no |
| <a name="input_vm_bridge_1"></a> [vm\_bridge\_1](#input\_vm\_bridge\_1) | Primary network bridge | `string` | `"vmbr0"` | no |
| <a name="input_vm_bridge_2"></a> [vm\_bridge\_2](#input\_vm\_bridge\_2) | Secondary network bridge | `string` | `"vmbr1"` | no |
| <a name="input_vm_datastore"></a> [vm\_datastore](#input\_vm\_datastore) | Storage for VM disk | `string` | n/a | yes |
| <a name="input_vm_disk_size"></a> [vm\_disk\_size](#input\_vm\_disk\_size) | Disk size in GB | `number` | `32` | no |
| <a name="input_vm_gateway"></a> [vm\_gateway](#input\_vm\_gateway) | Default gateway for primary network | `string` | n/a | yes |
| <a name="input_vm_id"></a> [vm\_id](#input\_vm\_id) | Unique VM ID in Proxmox | `number` | n/a | yes |
| <a name="input_vm_ip_primary"></a> [vm\_ip\_primary](#input\_vm\_ip\_primary) | Primary IP address with CIDR | `string` | n/a | yes |
| <a name="input_vm_ip_secondary"></a> [vm\_ip\_secondary](#input\_vm\_ip\_secondary) | Secondary IP address with CIDR | `string` | `""` | no |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | Name of the VM | `string` | n/a | yes |
| <a name="input_vm_node_name"></a> [vm\_node\_name](#input\_vm\_node\_name) | Proxmox node to place the VM on | `string` | n/a | yes |
| <a name="input_vm_tags"></a> [vm\_tags](#input\_vm\_tags) | List of tags to apply to the VM | `list(string)` | `[]` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ipv4_addresses"></a> [ipv4\_addresses](#output\_ipv4\_addresses) | All IPv4 addresses per network interface reported by the QEMU guest agent (empty list if the agent is disabled or not running) |
| <a name="output_primary_ip"></a> [primary\_ip](#output\_primary\_ip) | Primary IPv4 address - DEPRECATED: Use 'ipv4\_addresses' output instead |
| <a name="output_secondary_ip"></a> [secondary\_ip](#output\_secondary\_ip) | Secondary IPv4 address - DEPRECATED: Use 'ipv4\_addresses' output instead |
| <a name="output_vm_id"></a> [vm\_id](#output\_vm\_id) | The VM's numeric identifier in Proxmox |
| <a name="output_vm_name"></a> [vm\_name](#output\_vm\_name) | The VM's display name in Proxmox |
<!-- END_TF_DOCS -->
