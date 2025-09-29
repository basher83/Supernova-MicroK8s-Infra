---
Task ID: PREP-002
Title: Configure terraform.tfvars from example
Priority: P0
Duration: 30m
Dependencies: PREP-001
Status: 🔄 Ready
Created: 2025-09-25
Updated: 2025-09-25
---

## Objective

Configure Terraform variables by copying and customizing terraform.tfvars.example to create terraform.tfvars file with proper Proxmox settings, VM template ID, network configuration, and SSH credentials for deploying 3 VMs (3 MicroK8s nodes).

## Success Criteria

- [ ] terraform.tfvars file created with all required variables
- [ ] Proxmox credentials and endpoint configured
- [ ] Template ID set to 7024 (from PREP-001)
- [ ] SSH public key configured
- [ ] Network settings validated for dual network setup
- [ ] VM specifications confirmed within available resources
- [ ] `terraform plan` runs successfully without errors

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

## Troubleshooting

### Common Issues:

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

### Debug Commands:

```bash
# Check Proxmox API connectivity
curl -k https://YOUR_PROXMOX_IP:8006/api2/json/version

# Validate terraform syntax
terraform fmt -check
```

## Next Steps

- PREP-003: Initialize Terraform and validate Proxmox connectivity
- INFRA-001: Deploy infrastructure with terraform apply

## Resources

- [Terraform Proxmox Provider Documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [SSH Key Generation Guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key)
- [Proxmox Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration)
