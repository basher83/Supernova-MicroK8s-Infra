---
Task: Create Proxmox VM template from Ubuntu Server
Task ID: PREP-001
Priority: P0
Estimated Time: 1 hours
Dependencies: None
Status: ✅ Complete
Created: 2025-09-25
Updated: 2025-09-25
---

## Objective

Create a standardized Ubuntu Server 22.04 LTS VM template in Proxmox that will serve as the base for deploying 6 VMs (2 master nodes, 3 worker nodes, and 1 jumpbox) for the MicroK8s cluster. This template must include cloud-init support and qemu-guest-agent for Terraform automation.

## Prerequisites

- [x] Proxmox VE server accessible and operational
- [x] Administrative access to Proxmox web interface
- [x] Sufficient storage space for VM template (minimum 20GB)
- [x] Internet connectivity for downloading Ubuntu ISO
- [x] Basic understanding of Proxmox VM management

## Implementation Steps

### 1. **Download Ubuntu Server ISO**

Download the Ubuntu Server 22.04 LTS ISO to your local machine or directly to Proxmox:

```bash
# Download Ubuntu Server 22.04 LTS ISO
wget https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-live-server-amd64.iso

# Upload to Proxmox storage (if downloaded locally)
# Use Proxmox web interface: Datacenter > Storage > local > ISO Images > Upload
```

### 2. **Create VM in Proxmox**

Create a new VM with the following specifications:

- **VM ID**: 7024
- **Name**: prod24
- **OS Type**: Linux 6.x - 2.6 Kernel
- **ISO Image**: ubuntu-22.04.4-server-cloudimg-amd64.img
- **System**:
  - BIOS: OVMF (UEFI)
  - Add EFI Disk: Yes
  - Machine: q35
- **Hard Disk**:
  - Bus/Device: SCSI 0
  - Storage: local-lvm (or preferred storage)
  - Disk size: 4.5 GB
  - Format: qcow2
- **CPU**:
  - Sockets: 1
  - Cores: 1
  - Type: host
- **Memory**: 1024 MB (1GB)
- **Network**:
  - Bridge: vmbr0
  - Model: VirtIO (paravirtualized)

### 3. **Install Ubuntu Server**

Start the VM and perform Ubuntu installation:

1. Boot from ISO and select "Try or Install Ubuntu Server"
2. Choose language and keyboard layout
3. Network configuration: Use DHCP (default)
4. Configure proxy: Leave blank
5. Configure Ubuntu archive mirror: Use default
6. Guided storage configuration: Use entire disk
7. Profile setup:
   - Name: ubuntu
   - Server name: ubuntu-template
   - Username: ubuntu
   - Password: (set a temporary password)
8. SSH Setup: Install OpenSSH server
9. Featured Server Snaps: Skip for now
10. Complete installation and reboot

### 4. **Post-Installation Configuration**

After first boot, configure the system for template use:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y cloud-init qemu-guest-agent

# Enable and start qemu-guest-agent
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

# Clean cloud-init for template preparation
sudo cloud-init clean
sudo rm -rf /var/lib/cloud/instances
sudo rm -rf /var/log/cloud-init*

# Clear bash history and temporary files
history -c
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Clear machine-id for unique identification
sudo truncate -s 0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# Shutdown the VM
sudo shutdown -h now
```

### 5. **Convert VM to Template**

In Proxmox web interface:

1. Right-click on the VM (ubuntu-server-template)
2. Select "Convert to template"
3. Confirm the conversion

## Success Criteria

- [x] Ubuntu Server 22.04 LTS VM created with specified configuration
- [x] qemu-guest-agent installed and enabled
- [x] cloud-init installed and configured
- [x] VM successfully converted to template
- [x] Template can be cloned without errors
- [ ] Cloned VM receives unique machine-id and IP address # This is done via terraform

## Validation

Test the template by creating a clone:

```bash
# Create a test clone via Proxmox CLI (optional)
qm clone 9000 999 --name test-clone

# Start the cloned VM
qm start 999

# Verify services are running in the cloned VM
# SSH into the clone and check:
sudo systemctl status qemu-guest-agent
sudo systemctl status cloud-init
ip addr show  # Should have unique IP
cat /etc/machine-id  # Should have unique machine-id
```

Expected output:

- qemu-guest-agent service: active (running)
- cloud-init service: active (running)
- VM receives unique IP address via DHCP
- Machine-id is unique for each clone
- SSH access works with ubuntu user

## Notes

- Template VM ID 9000 is conventional for templates in Proxmox
- The template will be used by Terraform to provision multiple VMs
- Keep the ubuntu user password simple for initial setup; it will be managed by cloud-init in actual deployments
- EFI boot is required for modern Ubuntu versions
- VirtIO drivers provide better performance for paravirtualized environment

Template is configured with:
VM ID: 7024
Name: prod24
OS: Ubuntu 24.04
User: ansible
SSH key: production.pub

## References

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Ubuntu Server 22.04 LTS](https://ubuntu.com/server)
- [Cloud-init Documentation](https://cloud-init.readthedocs.io/)
- [QEMU Guest Agent](https://pve.proxmox.com/wiki/Qemu-guest-agent)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
