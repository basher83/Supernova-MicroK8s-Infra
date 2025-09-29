# Terraform Infrastructure for MicroK8s Homelab

This directory contains the Terraform configuration for deploying a MicroK8s Kubernetes cluster on Proxmox.

## Architecture

The infrastructure consists of:

- **3 MicroK8s Nodes**: All nodes run MicroK8s and participate equally in the cluster
- **1 Jumpbox**: Bastion host with dual-network access for secure cluster management

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

```bash
terraform apply
```

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

## Best Practices

1. **State Management**: Consider using remote state backend for production
2. **Variable Sensitivity**: Keep `proxmox_password` in environment variables
3. **Resource Sizing**: Adjust VM specifications based on available resources
4. **Network Security**: Ensure proper firewall rules between networks

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
terraform apply -target=module.k8s_cluster

# State inspection
terraform state list
terraform state show module.jumpbox
```

## Dependencies

- Terraform >= 1.3.0
- Proxmox Provider (bpg/proxmox) >= 0.38.0
- VM Template (created in PREP-001)
- Configured network bridges in Proxmox

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
