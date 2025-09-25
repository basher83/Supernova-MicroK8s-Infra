---
Task ID: SETUP-001
Title: Deploy 3 Ubuntu VMs on Proxmox
Priority: P0
Duration: 2h
Dependencies: None
Status: 🔄 Ready
Created: 2025-01-26
Updated: 2025-01-26
---

## Objective

Deploy 3 Ubuntu Server VMs on Proxmox to serve as the foundation for your MicroK8s homelab cluster. This task focuses on creating a solid infrastructure base for Kubernetes.

## Success Criteria

- [ ] 3 Ubuntu VMs created in Proxmox
- [ ] VMs configured with:
  - Ubuntu Server 22.04 LTS
  - 4 vCPUs, 8GB RAM minimum each
  - 100GB storage per VM
  - Bridged networking
- [ ] VMs accessible via SSH
- [ ] Basic network connectivity verified

## Prerequisites

- Proxmox VE server running
- Access to Proxmox web interface
- Ubuntu Server 22.04 LTS ISO uploaded to Proxmox
- Network bridge configured for VM access

## Implementation Steps

### 1. Access Proxmox Web Interface

1. Open your browser and navigate to your Proxmox server: `https://your-proxmox-server:8006`
2. Log in with your credentials

### 2. Create First VM (Control Plane Node)

1. Click **Create VM** in the top-right corner
2. **General Tab**:

   - VM ID: `201`
   - Name: `microk8s-master-1`
   - Start at boot: `No`

3. **OS Tab**:

   - Use CD/DVD disc image file: Select Ubuntu Server 22.04 ISO
   - Guest OS: `Linux 6.x - 2.6 Kernel`

4. **System Tab**:

   - Default settings (QEMU Agent enabled)

5. **Disks Tab**:

   - Bus/Device: `VirtIO Block`
   - Storage: Your storage pool
   - Disk size: `100 GiB`
   - Discard: `on`

6. **CPU Tab**:

   - Cores: `4`
   - Type: `host`

7. **Memory Tab**:

   - Memory: `8192 MiB` (8GB)

8. **Network Tab**:

   - Bridge: Your network bridge
   - Model: `VirtIO (paravirtualized)`

9. Click **Finish** to create the VM

### 3. Clone VMs for Worker Nodes

Instead of creating each VM manually, clone the first VM:

1. Right-click the created VM → **Clone**
2. Name: `microk8s-master-2`
3. VM ID: `202`
4. Mode: `Full Clone`
5. Click **Clone**

6. Repeat for third VM:
   - Name: `microk8s-master-3`
   - VM ID: `203`
   - Full Clone

### 4. Configure VM Networking

For each VM, ensure proper network configuration:

1. Start each VM: Right-click → **Start**
2. Open VM console
3. During Ubuntu installation:
   - Language: English
   - Keyboard: Your preference
   - Network: DHCP (for now)
   - Proxy: None
   - Mirror: Default
   - Storage: Use entire disk
   - Profile setup: Configure as needed
   - SSH: Install OpenSSH server
   - Featured Server Snaps: None

### 5. Verify VM Access

After installation completes:

1. Get IP addresses from Proxmox VM consoles or DHCP server
2. Test SSH access:

   ```bash
   ssh ubuntu@VM_IP_ADDRESS
   ```

3. Update `/etc/hosts` on your local machine for easy access:
   ```bash
   # Add to /etc/hosts
   VM1_IP microk8s-master-1
   VM2_IP microk8s-master-2
   VM3_IP microk8s-master-3
   ```

## Validation Commands

```bash
# Test SSH connectivity to all nodes
for node in microk8s-master-1 microk8s-master-2 microk8s-master-3; do
  echo "Testing $node..."
  ssh ubuntu@$node "hostname && uptime"
done

# Verify Ubuntu version on all nodes
for node in microk8s-master-1 microk8s-master-2 microk8s-master-3; do
  echo "Ubuntu version on $node:"
  ssh ubuntu@$node "lsb_release -a"
done

# Check available resources
for node in microk8s-master-1 microk8s-master-2 microk8s-master-3; do
  echo "Resources on $node:"
  ssh ubuntu@$node "free -h && nproc && df -h /"
done
```

## Learning Objectives

- Proxmox VM management and configuration
- Ubuntu Server installation process
- Network configuration in virtualized environments
- SSH access and key management basics
- Resource allocation for container workloads

## Troubleshooting

### VM Won't Start

- Check Proxmox resource allocation (CPU, RAM, storage)
- Verify ISO is properly uploaded
- Check Proxmox logs for hardware conflicts

### SSH Connection Fails

- Verify VM IP address from Proxmox console
- Check firewall settings
- Ensure SSH service is running: `sudo systemctl status ssh`

### Network Issues

- Verify bridge configuration in Proxmox
- Check DHCP server if using dynamic IPs
- Test connectivity from Proxmox host to VMs

## Next Steps

Once VMs are deployed and accessible, proceed to [SETUP-002: Install MicroK8s on all nodes](../setup/SETUP-002-install-microk8s.md).

## Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Ubuntu Server Installation Guide](https://ubuntu.com/server/docs/installation)
- [MicroK8s Hardware Requirements](https://microk8s.io/docs/recommendations)
