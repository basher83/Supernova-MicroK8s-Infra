# Proxmox Build Template Playbook

Ansible playbook for creating Proxmox VM templates from cloud images using the `build-template` script with cloud-init integration.

## Overview

This playbook automates the creation of Proxmox VM templates by:

- Downloading and configuring cloud images (Ubuntu, Debian, etc.)
- Configuring hardware specifications (CPU, memory, disk)
- Setting up networking (single or dual-homed)
- Injecting cloud-init vendor data for automation
- Verifying template creation

## Prerequisites

- Proxmox VE cluster with `build-template` script installed
- Cloud image downloaded to `/var/lib/vz/template/iso/`
- Vendor data file (`microk8s-data.yml`) in `/var/lib/vz/snippets/` on all nodes
- Ansible control node with access to Proxmox hosts

## Quick Start

### 1. Basic Template Creation

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml
```

This creates a template with default settings:

- **VM ID**: 7024
- **Name**: prod24
- **Image**: Ubuntu 24.04 Server
- **CPU**: 2 cores
- **Memory**: 2048 MB
- **Disk**: 32 GB
- **BIOS**: OVMF (UEFI)

### 2. Dry Run (Test Mode)

Test without creating:

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml \
  -e "dry_run=true"
```

### 3. Custom Configuration

Override any variable:

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml \
  -e "template_id=7025" \
  -e "template_name=ubuntu24-custom" \
  -e "memory_mb=4096" \
  -e "cpu_cores=4" \
  -e "disk_resize=50G"
```

## Configuration Variables

### Required Variables

| Variable           | Default                                                           | Description                  |
| ------------------ | ----------------------------------------------------------------- | ---------------------------- |
| `template_id`      | `7024`                                                            | Unique VM ID (100-999999999) |
| `template_name`    | `prod24`                                                          | Template name in Proxmox     |
| `cloud_image_path` | `/var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img` | Path to cloud image          |

### Hardware Configuration

| Variable          | Default           | Options                  | Description                |
| ----------------- | ----------------- | ------------------------ | -------------------------- |
| `bios_type`       | `ovmf`            | `ovmf`, `seabios`        | BIOS type (UEFI or legacy) |
| `cpu_cores`       | `2`               | `1-64`                   | Number of CPU cores        |
| `cpu_sockets`     | `1`               | `1-4`                    | Number of CPU sockets      |
| `cpu_type`        | `host`            | `host`, `kvm64`, etc.    | CPU type                   |
| `machine_type`    | `q35`             | `q35`, `pc`              | Machine type               |
| `memory_mb`       | `2048`            | `512-65536`              | Memory in MB               |
| `disk_resize`     | `32G`             | `1G-500G`                | Boot disk size increase    |
| `storage_name`    | `local-lvm`       | `local-lvm`, `local-zfs` | Proxmox storage            |
| `scsi_controller` | `virtio-scsi-pci` | `virtio-scsi-pci`, `lsi` | SCSI controller            |
| `os_type`         | `l26`             | `l26`, `win10`, etc.     | OS type                    |

### Network Configuration

#### Primary Network

| Variable      | Default  | Description                               |
| ------------- | -------- | ----------------------------------------- |
| `net_bridge`  | `vmbr0`  | Network bridge                            |
| `net_type`    | `virtio` | Network card type                         |
| `net_vlan`    | `""`     | VLAN tag (leave empty for none)           |
| `net_ip`      | `dhcp`   | IP address (`dhcp` or `192.168.1.100/24`) |
| `net_gateway` | `""`     | Gateway (required for static IP)          |

#### Secondary Network (Optional)

| Variable       | Default  | Description                              |
| -------------- | -------- | ---------------------------------------- |
| `net2_bridge`  | `""`     | Second network bridge (empty = disabled) |
| `net2_type`    | `virtio` | Second network card type                 |
| `net2_vlan`    | `""`     | Second VLAN tag                          |
| `net2_ip`      | `dhcp`   | Second IP address                        |
| `net2_gateway` | `""`     | Second gateway                           |

### Cloud-init Configuration

| Variable           | Default             | Description                                 |
| ------------------ | ------------------- | ------------------------------------------- |
| `vendor_data_file` | `microk8s-data.yml` | Vendor data file in `/var/lib/vz/snippets/` |
| `ssh_keys_file`    | `""`                | Path to SSH public keys file                |
| `cloud_init_user`  | `""`                | Default username (empty = distro default)   |

### Other Options

| Variable  | Default | Description                                 |
| --------- | ------- | ------------------------------------------- |
| `dry_run` | `false` | Test mode - show commands without executing |

## Usage Examples

### Example 1: High-Spec Development Template

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml \
  -e "template_id=7030" \
  -e "template_name=dev-high-spec" \
  -e "cpu_cores=8" \
  -e "cpu_sockets=1" \
  -e "memory_mb=16384" \
  -e "disk_resize=100G" \
  -e "storage_name=local-zfs"
```

### Example 2: Dual-Homed Network Template

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml \
  -e "template_id=7031" \
  -e "template_name=dual-network" \
  -e "net_bridge=vmbr0" \
  -e "net_ip=dhcp" \
  -e "net2_bridge=vmbr1" \
  -e "net2_ip=192.168.4.100/24" \
  -e "net2_gateway=192.168.4.1"
```

### Example 3: Static IP Template

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml \
  -e "template_id=7032" \
  -e "template_name=static-ip" \
  -e "net_ip=192.168.30.100/24" \
  -e "net_gateway=192.168.30.1"
```

### Example 4: VLAN-Tagged Network

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml \
  -e "template_id=7033" \
  -e "template_name=vlan-template" \
  -e "net_bridge=vmbr0" \
  -e "net_vlan=100" \
  -e "net2_bridge=vmbr1" \
  -e "net2_vlan=200"
```

### Example 5: Debian 12 Template

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml \
  -e "template_id=7034" \
  -e "template_name=debian12-template" \
  -e "cloud_image_path=/var/lib/vz/template/iso/debian-12-generic-amd64.qcow2"
```

### Example 6: SeaBIOS default for Proxmox

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml \
  -e "template_id=7035" \
  -e "template_name=legacy-bios" \
  -e "bios_type=seabios"
```

### Example 7: Using External Variables File

Create `vars/prod-template.yml`:

```yaml
template_id: 7040
template_name: "production-k8s"
cpu_cores: 4
memory_mb: 8192
disk_resize: 64G
net_bridge: vmbr0
net_ip: dhcp
net2_bridge: vmbr1
net2_ip: 192.168.4.50/24
vendor_data_file: microk8s-data.yml
```

Run:

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-build-template.yml \
  -e "@vars/prod-template.yml"
```

## Workflow

The playbook performs the following steps:

1. **Pre-flight Checks**

   - Verifies cloud image exists
   - Checks if VM ID is already in use
   - Confirms vendor data file exists in snippets

2. **Build Template**

   - Constructs the `build-template` command with all parameters
   - Displays the command for verification
   - Executes the template creation

3. **Verification**

   - Confirms template was created successfully
   - Displays summary information

4. **Output**
   - Shows template details (ID, name, storage, network)

## Troubleshooting

### Error: VM ID already exists

```bash
# List existing VMs to find available ID
ssh root@proxmox "qm list"

# Remove old VM if needed
ssh root@proxmox "qm destroy 7024"

# Or use a different ID
ansible-playbook ... -e "template_id=7025"
```

### Error: Cloud image not found

```bash
# Verify image path
ssh root@proxmox "ls -lh /var/lib/vz/template/iso/"

# Download Ubuntu 24.04 image
ssh root@proxmox "wget -P /var/lib/vz/template/iso/ \
  https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
```

### Error: Vendor data file not found

```bash
# Copy vendor data to all nodes
ansible-playbook -i inventory/proxmox.yml playbooks/add-file-to-host.yml
```

### Verify Template Creation

```bash
# List templates
ssh root@proxmox "qm list | grep template"

# View template config
ssh root@proxmox "qm config 7024"

# Test clone template
ssh root@proxmox "qm clone 7024 999 --name test-clone"
ssh root@proxmox "qm start 999"
```

## Integration with Terraform

After creating the template, update your Terraform configuration:

```hcl
# terraform/variables.tf
variable "template_id" {
  description = "ID of the VM template to clone"
  type        = number
  default     = 7024  # Match template_id from playbook
}
```

## Cloud Images

### Ubuntu Cloud Images

```bash
# Ubuntu 24.04 LTS
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img

# Ubuntu 22.04 LTS
wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
```

### Debian Cloud Images

```bash
# Debian 12 (Bookworm)
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
```

## Best Practices

1. **Use UEFI (OVMF)**: Modern distributions require UEFI boot

   ```bash
   -e "bios_type=ovmf"
   ```

2. **Size appropriately**: Match template specs to workload

   - Development: 2 cores, 2-4GB RAM
   - Production: 4+ cores, 8+ GB RAM

3. **Test first**: Always use dry-run before production

   ```bash
   -e "dry_run=true"
   ```

4. **Vendor data**: Ensure qemu-guest-agent is in cloud-init config

   ```yaml
   packages:
     - qemu-guest-agent
   runcmd:
     - systemctl enable qemu-guest-agent
     - systemctl start qemu-guest-agent
   ```

5. **Consistent IDs**: Use a numbering scheme
   - 7000-7099: Production templates
   - 7100-7199: Development templates
   - 7200-7299: Test templates

## Related Playbooks

- **[add-file-to-host.yml](add-file-to-host.yml)**: Upload vendor data to all Proxmox nodes
- **[playbook.yml](playbook.yml)**: Main deployment playbook for VMs created from templates

## References

- [Proxmox Cloud-Init Documentation](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
- [Cloud-init Documentation](https://cloud-init.readthedocs.io/)
- [Build-template Script Documentation](../../docs/build-template-script.md)
