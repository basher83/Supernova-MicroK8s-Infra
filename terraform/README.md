# Terraform Infrastructure for MicroK8s Homelab

This directory contains the Terraform configuration for deploying a MicroK8s Kubernetes cluster on Proxmox.

## Architecture

The infrastructure consists of:

- **3 MicroK8s Nodes**: All nodes run MicroK8s and participate equally in the cluster
- **1 Jumpbox**: Bastion host with dual-network access for secure cluster management

## Multi-Node Deployment

By default, each MicroK8s node is deployed on a separate Proxmox node for high availability:

- **microk8s-1** → `target_node_1` (default: pve01)
- **microk8s-2** → `target_node_2` (default: pve02)
- **microk8s-3** → `target_node_3` (default: pve03)
- **jumpbox** → `target_node_1` (same as first MicroK8s node)

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

### Proxmox Lock Errors During Multi-VM Deployment

**Issue**: Creating multiple VMs simultaneously can cause Proxmox VE lock errors due to I/O bottlenecks.

**Root Cause**: Proxmox VE has limited I/O capacity when handling concurrent VM creation operations, especially with cloud image resizing.

**Solutions**:

1. **Sequential Deployment (Recommended)**:
   ```bash
   terraform apply -parallelism=1
   ```

2. **Targeted Deployment**:
   ```bash
   # Deploy jumpbox first
   terraform apply -target=module.jumpbox

   # Then deploy MicroK8s nodes
   terraform apply -target=module.microk8s_nodes
   ```

3. **Retry on Failure**:
   ```bash
   # If lock errors occur, destroy and retry with sequential deployment
   terraform destroy
   terraform apply -parallelism=1
   ```

**Related Issues**:
- [Proxmox Provider Issue #1929](https://github.com/Telmate/terraform-provider-proxmox/issues/1929)
- [Proxmox Provider Issue #995](https://github.com/Telmate/terraform-provider-proxmox/issues/995)

**Feature Request**: Consider supporting [OpenTofu provider parallelization configuration](https://github.com/opentofu/opentofu/issues/2466) with 👍 to help with prioritization.

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

<!-- END_TF_DOCS -->
