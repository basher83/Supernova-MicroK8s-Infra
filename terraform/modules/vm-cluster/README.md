<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.84.1 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_vms"></a> [cluster\_vms](#module\_cluster\_vms) | ../vm | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_boot_down_delay"></a> [boot\_down\_delay](#input\_boot\_down\_delay) | Delay in seconds when shutting down VMs | `number` | `0` | no |
| <a name="input_boot_up_delay"></a> [boot\_up\_delay](#input\_boot\_up\_delay) | Delay in seconds before starting VMs on boot | `number` | `0` | no |
| <a name="input_cloud_init_config"></a> [cloud\_init\_config](#input\_cloud\_init\_config) | Cloud-init configuration for all nodes | <pre>object({<br/>    datastore_id = string<br/>    interface    = optional(string, "ide0")<br/>    dns = optional(object({<br/>      domain  = optional(string)<br/>      servers = optional(list(string))<br/>    }))<br/>    user = optional(object({<br/>      name     = optional(string)<br/>      password = optional(string)<br/>      keys     = optional(list(string))<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_cluster_tags"></a> [cluster\_tags](#input\_cluster\_tags) | Tags to apply to all VMs in the cluster (in addition to per-node tags) | `list(string)` | `[]` | no |
| <a name="input_cpu_type"></a> [cpu\_type](#input\_cpu\_type) | CPU type for all nodes | `string` | `"host"` | no |
| <a name="input_custom_user_data_file_id"></a> [custom\_user\_data\_file\_id](#input\_custom\_user\_data\_file\_id) | Optional custom cloud-init user data file ID to use for all nodes | `string` | `null` | no |
| <a name="input_default_cpu_cores"></a> [default\_cpu\_cores](#input\_default\_cpu\_cores) | Default CPU cores for all nodes (can be overridden per node) | `number` | `4` | no |
| <a name="input_default_memory"></a> [default\_memory](#input\_default\_memory) | Default memory in MB for all nodes (can be overridden per node) | `number` | `8192` | no |
| <a name="input_disk_configuration"></a> [disk\_configuration](#input\_disk\_configuration) | Default disk configuration for all nodes | <pre>map(object({<br/>    size        = number<br/>    file_format = optional(string, "raw")<br/>    iothread    = optional(bool, true)<br/>    ssd         = optional(bool, true)<br/>    discard     = optional(string, "on")<br/>    main_disk   = optional(bool, false)<br/>  }))</pre> | <pre>{<br/>  "scsi0": {<br/>    "main_disk": true,<br/>    "size": 50<br/>  }<br/>}</pre> | no |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | Network CIDR suffix for all nodes (e.g., '24' for /24) | `string` | `"24"` | no |
| <a name="input_network_gateway"></a> [network\_gateway](#input\_network\_gateway) | Network gateway IP for all nodes | `string` | n/a | yes |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces) | Network interface configuration template for all nodes | <pre>map(object({<br/>    bridge     = string<br/>    firewall   = optional(bool, false)<br/>    model      = optional(string, "virtio")<br/>    mtu        = optional(number, 1500)<br/>    rate_limit = optional(string)<br/>    vlan_id    = optional(number)<br/>  }))</pre> | <pre>{<br/>  "net0": {<br/>    "bridge": "vmbr0"<br/>  },<br/>  "net1": {<br/>    "bridge": "vmbr1"<br/>  }<br/>}</pre> | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Map of cluster nodes with their configuration. Each key is the VM name.<br/>Required per-node fields: pve\_node, ip\_address<br/>Optional per-node fields: cpu\_cores, memory, disk\_size, disk\_datastore, tags, vm\_id, vlan\_id, mac\_address, ip\_address\_secondary | <pre>map(object({<br/>    pve_node             = string           # Proxmox node to deploy on<br/>    ip_address           = string           # Primary NIC IP address (without CIDR)<br/>    ip_address_secondary = optional(string) # Secondary NIC IP address (without CIDR)<br/>    cpu_cores            = optional(number) # Override default CPU cores<br/>    memory               = optional(number) # Override default memory (MB)<br/>    disk_size            = optional(number) # Override default disk size (GB)<br/>    disk_datastore       = optional(string) # Override default disk datastore<br/>    efi_datastore        = optional(string) # Override EFI disk datastore<br/>    tags                 = optional(list(string), [])<br/>    vm_id                = optional(number)<br/>    vlan_id              = optional(number)<br/>    mac_address          = optional(string)<br/>    network_bridge       = optional(string) # Override default network bridge<br/>    boot_order           = optional(number, 0)<br/>    user_data_file_id    = optional(string) # Custom cloud-init user data file<br/>    template_node        = optional(string) # Override template source node<br/>  }))</pre> | n/a | yes |
| <a name="input_start_on_boot"></a> [start\_on\_boot](#input\_start\_on\_boot) | Start VMs automatically when Proxmox node boots | `bool` | `true` | no |
| <a name="input_start_on_deploy"></a> [start\_on\_deploy](#input\_start\_on\_deploy) | Start VMs immediately after deployment | `bool` | `true` | no |
| <a name="input_template_datastore"></a> [template\_datastore](#input\_template\_datastore) | Datastore where template resides and where VM disks will be created | `string` | `"local-lvm"` | no |
| <a name="input_template_id"></a> [template\_id](#input\_template\_id) | VM template ID to clone from (must be pre-existing) | `number` | n/a | yes |
| <a name="input_template_node"></a> [template\_node](#input\_template\_node) | Proxmox node where the template is located (for cross-node cloning) | `string` | `null` | no |
| <a name="input_vm_agent"></a> [vm\_agent](#input\_vm\_agent) | QEMU guest agent configuration for all VMs | <pre>object({<br/>    enabled = optional(bool, true)<br/>    timeout = optional(string, "15m")<br/>    trim    = optional(bool, false)<br/>    type    = optional(string, "virtio")<br/>  })</pre> | <pre>{<br/>  "enabled": true,<br/>  "timeout": "15m"<br/>}</pre> | no |
| <a name="input_vm_bios"></a> [vm\_bios](#input\_vm\_bios) | BIOS type for all VMs | `string` | `"ovmf"` | no |
| <a name="input_vm_display"></a> [vm\_display](#input\_vm\_display) | Display configuration for all VMs | <pre>object({<br/>    type   = optional(string, "std")<br/>    memory = optional(number, 16)<br/>  })</pre> | `{}` | no |
| <a name="input_vm_machine"></a> [vm\_machine](#input\_vm\_machine) | Machine type for all VMs | `string` | `"q35"` | no |
| <a name="input_vm_os"></a> [vm\_os](#input\_vm\_os) | Operating system type for all VMs | `string` | `"l26"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_ids"></a> [cluster\_ids](#output\_cluster\_ids) | Map of node names to their VM IDs |
| <a name="output_cluster_inventory"></a> [cluster\_inventory](#output\_cluster\_inventory) | Ansible-friendly inventory output with hostnames and IPs |
| <a name="output_cluster_ips"></a> [cluster\_ips](#output\_cluster\_ips) | Map of node names to their primary IPv4 addresses |
| <a name="output_cluster_macs"></a> [cluster\_macs](#output\_cluster\_macs) | Map of node names to their MAC addresses |
| <a name="output_cluster_nodes"></a> [cluster\_nodes](#output\_cluster\_nodes) | Map of all cluster nodes with their details |
| <a name="output_cluster_summary"></a> [cluster\_summary](#output\_cluster\_summary) | Human-readable cluster summary |
<!-- END_TF_DOCS -->
