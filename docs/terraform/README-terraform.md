# Terraform Infrastructure for MicroK8s Homelab

This directory contains the Terraform configuration for deploying a MicroK8s Kubernetes cluster on Proxmox.

## Architecture

The infrastructure consists of:

- **3 MicroK8s Nodes**: All nodes run MicroK8s and participate equally in the cluster
- **1 Jumpbox**: Bastion host with dual-network access for secure cluster management

## Multi-Node Deployment

**Multi-Node Deployment**: Template VM 7024 exists on 'lloyd'. Terraform automatically clones from lloyd to target nodes.

**Deployment Mapping**:

- **jumpbox** → `holly` (cloned from lloyd)
- **microk8s-1** → `lloyd` (local template)
- **microk8s-2** → `mable` (cloned from lloyd)
- **microk8s-3** → `holly` (cloned from lloyd)

**Proxmox Provider Behavior**: When `template_id` points to a VM on node A and `target_node` is node B, the provider automatically clones the template from A to B.

## Directory Structure

```text
terraform/
├── main.tf                   # Root module orchestration
├── variables.tf              # Input variable definitions
├── outputs.tf                # Output values
├── locals.tf                 # Local values and computed data
├── provider.tf               # Provider configuration
├── versions.tf               # Version constraints
├── terraform.tfvars.example  # Example configuration
│
└── modules/
    ├── proxmox-vm/          # Generic VM module
    ├── k8s-cluster/         # Kubernetes cluster orchestration module
    └── jumpbox/             # Jumpbox/bastion module
```

## Module Design

### proxmox-vm

Generic, reusable module for creating Proxmox VMs with:

- Dynamic network interface configuration
- Cloud-init support
- Flexible resource allocation

### k8s-cluster

Orchestrates creation of master and worker nodes:

- Uses `for_each` for node management
- Configures cluster networking
- Applies consistent tagging

### jumpbox

Dual-homed bastion host for secure access:

- Connected to both home and cluster networks
- Minimal resource footprint
- SSH proxy configuration

## Usage

### 1. Configure Variables

Copy and customize the example configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your settings:

- Proxmox credentials and endpoint
- Template ID (from PREP-001)
- Network configuration
- Resource specifications

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Apply Configuration

⚠️ **Important**: Proxmox can experience lock errors when creating multiple VMs simultaneously due to I/O bottlenecks.

**Recommended approach**:

```bash
# Option 1: Sequential deployment (recommended)
terraform apply -parallelism=1

# Option 2: Deploy jumpbox first, then nodes
terraform apply -target=module.jumpbox
terraform apply -target=module.microk8s_nodes
```

**Alternative**: If you encounter lock errors, destroy and retry with sequential deployment.

### 5. Generate Ansible Inventory

```bash
terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml
```

## Network Configuration

**Cluster Network Setup:**

- **Cluster Network** (192.168.4.0/24): Internal communication via vmbr1

**IP Allocations:**

- MicroK8s Nodes: 192.168.4.11-13
- Jumpbox: 192.168.30.240 (home), 192.168.4.240 (cluster)

## Outputs

The configuration provides:

- Cluster summary and node details
- Network configuration
- Ansible inventory in YAML format
- SSH proxy configuration for accessing nodes
- Next steps for cluster configuration

## Troubleshooting

### VM Template Availability Issues

**Issue**: `unable to find configuration file for VM 7024 on node 'target_node'`

**Root Cause**: VM templates in Proxmox VE are node-specific. The template VM exists on one node but deployment targets a different node.

**Proxmox Provider Automatic Cloning**:

The BPG Proxmox provider automatically handles cross-node template cloning:

```bash
# Template 7024 exists on 'lloyd'
# Terraform clones it to target nodes automatically
target_node_1 = "holly"  # Clones from lloyd → holly
target_node_2 = "mable"  # Clones from lloyd → mable
target_node_3 = "holly"  # Clones from lloyd → holly
```

**No Manual Template Management Required** - The provider handles template distribution automatically.

### EFI Disk Configuration Issues

**Issue**: `Parameter verification failed. (efidisk0: invalid format - missing key in comma-separated list property)`

**Root Cause**: EFI disk configuration issues when using UEFI boot with some Proxmox versions or configurations.

**Solutions**:

1. **Disable EFI Disk**:

   ```bash
   # In terraform.tfvars, set:
   efi_disk_enabled = false
   ```

2. **Use BIOS Boot**:

   ```bash
   # In terraform.tfvars, set:
   bios_type = "seabios"  # Instead of "ovmf"
   ```

3. **Check Proxmox Version**:
   - Ensure Proxmox VE is updated to latest version
   - Some older versions have EFI disk configuration issues

## Best Practices

1. **State Management**: Consider using remote state backend for production
2. **Variable Sensitivity**: Keep `pve_api_token` in environment variables
3. **Resource Sizing**: Adjust VM specifications based on available resources
4. **Network Security**: Ensure proper firewall rules between networks
5. **Deployment Strategy**: Use `-parallelism=1` for reliable multi-VM deployment

## Troubleshooting

**Common Issues:**

- Template not found: Verify template ID matches PREP-001 creation
- Network bridges missing: Confirm vmbr0/vmbr1 exist in Proxmox
- Resource constraints: Reduce memory/CPU if needed

**Debug Commands:**

```bash
# Detailed planning
terraform plan -out=tfplan

# Targeted resource updates
terraform apply -target=module.jumpbox
terraform apply -target=module.microk8s_nodes

# State inspection
terraform state list
terraform state show module.jumpbox
terraform state show module.microk8s_nodes
```

## Dependencies

- Terraform >= 1.3.0
- Proxmox Provider (bpg/proxmox) >= 0.38.0
- VM Template (created in PREP-001)
- Configured network bridges in Proxmox

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.3.0  |
| <a name="requirement_proxmox"></a> [proxmox](#requirement_proxmox)       | ~> 0.76.1 |

## Providers

No providers.

## Modules

| Name                                                                          | Source               | Version |
| ----------------------------------------------------------------------------- | -------------------- | ------- |
| <a name="module_jumpbox"></a> [jumpbox](#module_jumpbox)                      | ./modules/jumpbox    | n/a     |
| <a name="module_microk8s_nodes"></a> [microk8s_nodes](#module_microk8s_nodes) | ./modules/proxmox-vm | n/a     |

## Resources

No resources.

## Inputs

| Name                                                                                          | Description                                  | Type                                                                                             | Default                                                                                             | Required |
| --------------------------------------------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_bios_type"></a> [bios_type](#input_bios_type)                                  | BIOS type for VMs                            | `string`                                                                                         | `"ovmf"`                                                                                            |    no    |
| <a name="input_cluster_network"></a> [cluster_network](#input_cluster_network)                | Cluster network configuration                | <pre>object({<br/> gateway = string<br/> bridge = string<br/> cidr_suffix = string<br/> })</pre> | <pre>{<br/> "bridge": "vmbr1",<br/> "cidr_suffix": "/24",<br/> "gateway": "192.168.4.1"<br/>}</pre> |    no    |
| <a name="input_disk_datastore_id"></a> [disk_datastore_id](#input_disk_datastore_id)          | Datastore ID for VM disks                    | `string`                                                                                         | `"local-lvm"`                                                                                       |    no    |
| <a name="input_disk_discard"></a> [disk_discard](#input_disk_discard)                         | Enable discard for disk                      | `string`                                                                                         | `"on"`                                                                                              |    no    |
| <a name="input_disk_iothread"></a> [disk_iothread](#input_disk_iothread)                      | Enable I/O threads for disk                  | `bool`                                                                                           | `true`                                                                                              |    no    |
| <a name="input_disk_size"></a> [disk_size](#input_disk_size)                                  | Disk size in GB                              | `number`                                                                                         | `32`                                                                                                |    no    |
| <a name="input_efi_disk_enabled"></a> [efi_disk_enabled](#input_efi_disk_enabled)             | Enable EFI disk for UEFI boot                | `bool`                                                                                           | `true`                                                                                              |    no    |
| <a name="input_environment"></a> [environment](#input_environment)                            | Environment name                             | `string`                                                                                         | `"homelab"`                                                                                         |    no    |
| <a name="input_home_network"></a> [home_network](#input_home_network)                         | Home network configuration                   | <pre>object({<br/> gateway = string<br/> bridge = string<br/> })</pre>                           | <pre>{<br/> "bridge": "vmbr0",<br/> "gateway": "192.168.30.1"<br/>}</pre>                           |    no    |
| <a name="input_jumpbox_cluster_ip"></a> [jumpbox_cluster_ip](#input_jumpbox_cluster_ip)       | Jumpbox IP on cluster network (without CIDR) | `string`                                                                                         | `"192.168.4.240"`                                                                                   |    no    |
| <a name="input_jumpbox_home_ip"></a> [jumpbox_home_ip](#input_jumpbox_home_ip)                | Jumpbox IP on home network (with CIDR)       | `string`                                                                                         | `"192.168.30.240/24"`                                                                               |    no    |
| <a name="input_machine_type"></a> [machine_type](#input_machine_type)                         | Machine type for VMs                         | `string`                                                                                         | `"q35"`                                                                                             |    no    |
| <a name="input_node_specs"></a> [node_specs](#input_node_specs)                               | Specifications for MicroK8s nodes            | <pre>object({<br/> cpu_cores = number<br/> memory = number<br/> })</pre>                         | <pre>{<br/> "cpu_cores": 2,<br/> "memory": 4096<br/>}</pre>                                         |    no    |
| <a name="input_proxmox_insecure"></a> [proxmox_insecure](#input_proxmox_insecure)             | Allow insecure TLS connections to Proxmox    | `bool`                                                                                           | `true`                                                                                              |    no    |
| <a name="input_proxmox_ssh_username"></a> [proxmox_ssh_username](#input_proxmox_ssh_username) | SSH username for connecting to Proxmox nodes | `string`                                                                                         | `"root"`                                                                                            |    no    |
| <a name="input_pve_api_token"></a> [pve_api_token](#input_pve_api_token)                      | Proxmox API token for authentication         | `string`                                                                                         | n/a                                                                                                 |   yes    |
| <a name="input_pve_api_url"></a> [pve_api_url](#input_pve_api_url)                            | Proxmox API endpoint URL                     | `string`                                                                                         | `"https://192.168.1.100:8006/"`                                                                     |    no    |
| <a name="input_target_node_1"></a> [target_node_1](#input_target_node_1)                      | First Proxmox node for VM deployment         | `string`                                                                                         | `"pve01"`                                                                                           |    no    |
| <a name="input_target_node_2"></a> [target_node_2](#input_target_node_2)                      | Second Proxmox node for VM deployment        | `string`                                                                                         | `"pve02"`                                                                                           |    no    |
| <a name="input_target_node_3"></a> [target_node_3](#input_target_node_3)                      | Third Proxmox node for VM deployment         | `string`                                                                                         | `"pve03"`                                                                                           |    no    |
| <a name="input_template_id"></a> [template_id](#input_template_id)                            | ID of the VM template to clone               | `number`                                                                                         | n/a                                                                                                 |   yes    |
| <a name="input_vm_description"></a> [vm_description](#input_vm_description)                   | Description for VMs                          | `string`                                                                                         | `"Managed by Terraform"`                                                                            |    no    |

## Outputs

| Name                                                                                            | Description                                 |
| ----------------------------------------------------------------------------------------------- | ------------------------------------------- |
| <a name="output_ansible_inventory"></a> [ansible_inventory](#output_ansible_inventory)          | Ansible inventory in YAML format            |
| <a name="output_ansible_proxy_config"></a> [ansible_proxy_config](#output_ansible_proxy_config) | Ansible SSH proxy configuration via jumpbox |
| <a name="output_cluster_summary"></a> [cluster_summary](#output_cluster_summary)                | Cluster deployment summary                  |
| <a name="output_jumpbox_info"></a> [jumpbox_info](#output_jumpbox_info)                         | Jumpbox connection information              |
| <a name="output_microk8s_nodes"></a> [microk8s_nodes](#output_microk8s_nodes)                   | MicroK8s node details                       |
| <a name="output_network_info"></a> [network_info](#output_network_info)                         | Network configuration                       |
| <a name="output_next_steps"></a> [next_steps](#output_next_steps)                               | Next steps after infrastructure deployment  |

<!-- END_TF_DOCS -->
