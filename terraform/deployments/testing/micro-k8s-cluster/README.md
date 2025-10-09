# MicroK8s Cluster Deployment Example

This example demonstrates deploying a 3-node MicroK8s Kubernetes cluster using the `vm-cluster` module.

## Overview

This deployment creates:
- 3 Ubuntu VMs (microk8s-1, microk8s-2, microk8s-3)
- 4 CPU cores and 8GB RAM per node
- 50GB disk per node
- Network configuration with VLAN support
- Cloud-init for initial setup

## Prerequisites

1. **Proxmox Template**: A VM template must exist (default ID: 2000)
   - Ubuntu 22.04 LTS recommended
   - Cloud-init enabled
   - QEMU guest agent installed

2. **Network Configuration**: Ensure the network bridge and VLAN are configured in Proxmox

3. **Terraform**: Version >= 1.0

4. **Provider Authentication**: Set Proxmox credentials via environment variables:
   ```bash
   export PROXMOX_VE_USERNAME="root@pam"
   export PROXMOX_VE_PASSWORD="your-password"
   # OR use API token
   export PROXMOX_VE_API_TOKEN="user@realm!token-id=secret"
   ```

## Usage

### 1. Configure Variables

Copy the example variables file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your environment details:
- Proxmox endpoint and node name
- Template ID
- Network configuration
- SSH public keys

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Deploy the Cluster

```bash
terraform apply
```

### 5. Access the Cluster

After deployment, Terraform will output:
- IP addresses for each node
- VM IDs
- SSH connection commands
- Ansible inventory (JSON format)

Example output:
```
cluster_ips = {
  "microk8s-1" = "192.168.30.101"
  "microk8s-2" = "192.168.30.102"
  "microk8s-3" = "192.168.30.103"
}

ssh_commands = {
  "microk8s-1" = "ssh ubuntu@192.168.30.101"
  "microk8s-2" = "ssh ubuntu@192.168.30.102"
  "microk8s-3" = "ssh ubuntu@192.168.30.103"
}
```

## Configuration Options

### Per-Node Customization

You can customize individual nodes by modifying the `nodes` map in `main.tf`:

```hcl
nodes = {
  "microk8s-1" = {
    pve_node   = "pve"
    ip_address = "192.168.30.101"
    cpu_cores  = 4        # Custom CPU cores
    memory     = 16384    # Custom memory (16GB)
    disk_size  = 100      # Custom disk size (100GB)
    tags       = ["master"]  # Additional tags
  }
  # ... more nodes
}
```

### Network Customization

Modify network settings for different environments:

```hcl
network_interfaces = {
  net0 = {
    bridge     = "vmbr1"     # Different bridge
    vlan_id    = 100         # Different VLAN
    firewall   = true
    model      = "virtio"
  }
}
```

### Cloud-init Customization

Customize the initial VM configuration:

```hcl
cloud_init_config = {
  datastore_id = "local"
  interface    = "ide0"
  dns = {
    domain  = "example.local"
    servers = ["8.8.8.8", "1.1.1.1"]
  }
  user = {
    name     = "admin"
    password = "secure-password"  # Optional
    keys     = var.ssh_public_keys
  }
}
```

## Post-Deployment

After the VMs are deployed, you can configure MicroK8s using Ansible:

```bash
# From the ansible/ directory
ansible-playbook -i inventory/proxmox.yml playbooks/microk8s-cluster.yml
```

## Cleanup

To destroy the cluster:

```bash
terraform destroy
```

## Module Features Demonstrated

This example showcases:
- ✅ Multi-node cluster deployment with `for_each`
- ✅ Per-node configuration overrides
- ✅ Template-clone approach for fast deployment
- ✅ Network isolation with VLANs
- ✅ Cloud-init integration
- ✅ Structured outputs for automation
- ✅ Ansible inventory generation

## Customization Examples

### Single Node Setup

```hcl
nodes = {
  "microk8s-1" = {
    pve_node   = "pve"
    ip_address = "192.168.30.101"
  }
}
```

### 5-Node High Availability Cluster

```hcl
nodes = {
  "microk8s-master-1" = { pve_node = "pve1", ip_address = "192.168.30.101" }
  "microk8s-master-2" = { pve_node = "pve2", ip_address = "192.168.30.102" }
  "microk8s-master-3" = { pve_node = "pve3", ip_address = "192.168.30.103" }
  "microk8s-worker-1" = { pve_node = "pve1", ip_address = "192.168.30.111", memory = 16384 }
  "microk8s-worker-2" = { pve_node = "pve2", ip_address = "192.168.30.112", memory = 16384 }
}
```

### Multi-Node Distributed Deployment

```hcl
nodes = {
  "microk8s-1" = { pve_node = "pve1", ip_address = "192.168.30.101" }
  "microk8s-2" = { pve_node = "pve2", ip_address = "192.168.30.102" }
  "microk8s-3" = { pve_node = "pve3", ip_address = "192.168.30.103" }
}
```

## Troubleshooting

### Template Not Found
Ensure the template exists and the ID is correct:
```bash
# List VMs on Proxmox node
qm list | grep template
```

### Network Connectivity Issues
- Verify VLAN configuration in Proxmox
- Check bridge and gateway settings
- Ensure firewall rules allow traffic

### Cloud-init Not Running
- Verify qemu-guest-agent is installed in template
- Check cloud-init logs: `cloud-init status --long`

## Related Documentation

- [vm-cluster Module Documentation](../../../modules/vm-cluster/README.md)
- [vm Module Documentation](../../../modules/vm/README.md)
- [Proxmox VM Provisioning Guide](../../../../docs/terraform/proxmox-vm-provisioning-guide.md)

## License

Copyright 2025 RalZareck. Licensed under Apache 2.0.
