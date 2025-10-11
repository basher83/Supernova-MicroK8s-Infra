# Template with Custom Cloud-Init Example

This example demonstrates creating a Proxmox VM template with **custom cloud-init user-data configuration**. This approach allows you to pre-configure templates with specific users, packages, scripts, and system settings that will be applied when VMs are cloned.

## What This Does

1. **Uploads** custom cloud-init user-data.yaml to Proxmox as a snippet
2. **Downloads** Ubuntu cloud image from official repository
3. **Creates** a Proxmox VM template configured to use the custom cloud-init data
4. **Outputs** template ID and cloud-init file ID for use in clone operations

## Resources Used

This example demonstrates three key Proxmox resources:

- **`proxmox_virtual_environment_file`** - Uploads custom user-data.yaml snippet
- **`proxmox_virtual_environment_download_file`** - Downloads cloud image (via vm module)
- **`proxmox_virtual_environment_vm`** - Creates template VM (via vm module)

## Use Cases

- **Pre-configured users**: Create templates with specific users, SSH keys, and sudo access
- **Package pre-installation**: Templates with Docker, Kubernetes tools, or other software
- **Custom scripts**: Run initialization scripts on first boot
- **System hardening**: Apply security configurations to all cloned VMs
- **Development environments**: Standardized developer workstation templates
- **Production deployments**: Consistent server configurations across fleet

## Prerequisites

1. Proxmox VE cluster with API access
2. **SSH access to Proxmox host** (required for image import operations)
   - SSH user with appropriate permissions (e.g., `terraform` user)
   - SSH key authentication configured (password auth not recommended)
   - SSH agent forwarding enabled for your local SSH agent
3. **`local` datastore configured for snippets**
   - Verify: Proxmox Web UI → Datacenter → Storage → local → Content → ✓ Snippets
   - If not enabled: `pvesm set local --content vztmpl,iso,snippets`
4. Cloud image URL or local file
5. Network connectivity to download cloud images

## Quick Start

### 1. Prepare Cloud-Init Configuration

```bash
cd terraform/deployments/examples/template-with-custom-cloudinit

# Copy example user-data file
cp user-data.yaml.example user-data.yaml

# Edit user-data.yaml with your configuration
vim user-data.yaml
```

**Important**: Update the following in `user-data.yaml`:
- SSH public keys (`ssh_authorized_keys`)
- User password hash (generate with `mkpasswd`)
- Hostname and system configuration
- Packages to install
- Custom scripts or files

### 2. Copy Example Configuration

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Configure Variables

Edit `terraform.tfvars`:

```hcl
proxmox_endpoint = "https://proxmox.example.com:8006"
proxmox_node     = "lloyd"
template_name    = "ubuntu-24-04-custom-cloudinit-template"
template_id      = 2008

# Path to your customized user-data file
user_data_file = "user-data.yaml"

# Cloud image configuration
cloud_image_url      = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
cloud_image_filename = "noble-server-cloudimg-amd64.img"

# Storage configuration
cloud_init_datastore  = "local"       # Must support snippets
cloud_image_datastore = "local"       # File-based storage
datastore             = "local-lvm"   # VM disks
```

### 4. Set Up Authentication

```bash
# Ensure SSH agent is running and has your key loaded
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa  # Or your specific key

# Test SSH access to Proxmox
ssh terraform@proxmox-host "echo 'SSH working'"

# Set Proxmox API credentials
export PROXMOX_VE_USERNAME="root@pam"
export PROXMOX_VE_PASSWORD="your-password"
# OR
export PROXMOX_VE_API_TOKEN="user@realm!token=secret"
```

### 5. Deploy Template

```bash
tofu init
tofu plan
tofu apply
```

### 6. Verify Template Creation

```bash
# Via Terraform output
tofu output template_id
tofu output cloud_init_file_id

# Via Proxmox CLI
ssh root@proxmox "qm list | grep 2008"
ssh root@proxmox "pvesm list local | grep user-data"
```

## Cloud-Init User-Data Configuration

The `user-data.yaml` file uses standard cloud-init syntax. Here are common configurations:

### User Creation with SSH Keys

```yaml
#cloud-config
users:
  - name: ubuntu
    groups: [sudo]
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD... your-key-here
```

### Package Installation

```yaml
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
  - docker.io
  - kubernetes-client
  - vim
  - htop
```

### Run Custom Scripts

```yaml
runcmd:
  - systemctl enable docker
  - systemctl start docker
  - curl -sfL https://get.k3s.io | sh -
```

### Write Configuration Files

```yaml
write_files:
  - path: /etc/docker/daemon.json
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "10m",
          "max-file": "3"
        }
      }
    permissions: '0644'
```

See [cloud-init documentation](https://cloudinit.readthedocs.io/) for complete reference.

## Storage Requirements

This example uses three different storage locations:

| Storage Type              | Variable                  | Default       | Purpose                   |
| ------------------------- | ------------------------- | ------------- | ------------------------- |
| Cloud-init snippets       | `cloud_init_datastore`    | `local`       | user-data.yaml storage    |
| Cloud image downloads     | `cloud_image_datastore`   | `local`       | Downloaded cloud images   |
| VM disks                  | `datastore`               | `local-lvm`   | Template disk storage     |

**Important**:
- `local` must have **Snippets** content type enabled
- `local` is file-based storage (for ISOs, snippets)
- `local-lvm` is block-based storage (for VM disks only)

### Enable Snippets on Local Storage

```bash
# Via Proxmox CLI
pvesm set local --content vztmpl,iso,snippets

# Via Web UI
Datacenter → Storage → local → Edit → Content → ✓ Snippets
```

## Using the Template

Once created, clone VMs from this template:

### Manual Clone (Proxmox Web UI)

1. Right-click template → Clone
2. Configure VM-specific settings (name, ID, network)
3. Cloud-init configuration will run on first boot

### Terraform Clone

```hcl
module "my_vm" {
  source = "../../../modules/vm"

  vm_type = "clone"
  src_clone = {
    datastore_id = "local-lvm"
    tpl_id       = 2008  # From this template
  }

  vm_name = "my-custom-vm"
  # VM will inherit cloud-init configuration from template
  # Override cloud-init settings as needed
}
```

## Updating Template Configuration

To update the cloud-init configuration:

### Method 1: Update and Recreate

```bash
# Edit user-data.yaml
vim user-data.yaml

# Taint the cloud-init file to force re-upload
tofu taint 'proxmox_virtual_environment_file.cloud_init_user_data'

# Apply changes
tofu apply
```

### Method 2: Full Template Recreation

```bash
# Edit user-data.yaml
vim user-data.yaml

# Destroy and recreate template
tofu destroy
tofu apply
```

## Troubleshooting

### SSH Connection Failed

**Error**: `Error creating VM: SSH connection failed`

**Solution**:
1. Verify SSH agent: `ssh-add -l`
2. Test SSH access: `ssh terraform@proxmox-host`
3. Check provider SSH configuration in `provider.tf`

### Snippets Content Type Not Enabled

**Error**: `datastore 'local' does not support 'snippets' content type`

**Solution**:
```bash
# Enable snippets on local storage
ssh root@proxmox "pvesm set local --content vztmpl,iso,snippets"

# Verify
ssh root@proxmox "pvesm status | grep local"
```

### Cloud-Init Not Running on Cloned VM

**Symptoms**: User not created, packages not installed

**Debug**:
```bash
# SSH to cloned VM
ssh ubuntu@cloned-vm

# Check cloud-init status
sudo cloud-init status
sudo cloud-init analyze show

# View cloud-init logs
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
```

### User-Data File Not Found

**Error**: `Error reading file: user-data.yaml: no such file or directory`

**Solution**:
```bash
# Ensure file exists in deployment directory
ls -la user-data.yaml

# Or use absolute path in variables
user_data_file = "/absolute/path/to/user-data.yaml"
```

### Invalid Cloud-Init Syntax

**Symptoms**: Cloud-init fails silently

**Validation**:
```bash
# Validate YAML syntax
yamllint user-data.yaml

# Test locally (requires cloud-init installed)
cloud-init schema --config-file user-data.yaml
```

## Advanced Configurations

### Multi-User Setup

```yaml
users:
  - name: admin
    groups: [sudo]
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAA... admin-key
  - name: developer
    groups: [docker]
    ssh_authorized_keys:
      - ssh-rsa AAAA... dev-key
  - name: readonly
    groups: []
    ssh_authorized_keys:
      - ssh-rsa AAAA... readonly-key
```

### Docker + Kubernetes Tools

```yaml
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg

runcmd:
  # Install Docker
  - curl -fsSL https://get.docker.com | sh
  - usermod -aG docker ubuntu

  # Install kubectl
  - curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  - install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

  # Install Helm
  - curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Automated Ansible Pull

```yaml
packages:
  - ansible
  - git

runcmd:
  - ansible-pull -U https://github.com/yourorg/ansible-playbooks.git -i localhost, site.yml
```

## Comparison with Other Examples

| Feature                    | template-from-url | template-from-file | template-with-custom-cloudinit |
| -------------------------- | ----------------- | ------------------ | ------------------------------ |
| Automated download         | ✅                | ❌                  | ✅                              |
| Custom cloud-init          | ❌                | ❌                  | ✅                              |
| Pre-configured users       | ❌                | ❌                  | ✅                              |
| Package pre-installation   | ❌                | ❌                  | ✅                              |
| Custom scripts             | ❌                | ❌                  | ✅                              |
| Best for                   | Simple templates  | Hybrid workflows   | Production environments        |

## Related Examples

- **[template-from-url](../template-from-url/)** - Basic template with automated download
- **[template-from-file](../template-from-file/)** - Template from existing image file
- **[single-vm](../single-vm/)** - Clone VMs from this template
- **[microk8s-cluster](../microk8s-cluster/)** - Deploy clusters using this template

## Additional Resources

- [Proxmox VM Provisioning Guide](../../../../docs/terraform/proxmox-vm-provisioning-guide.md)
- [VM Module Documentation](../../../modules/vm/README.md)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Cloud-Init Examples](https://cloudinit.readthedocs.io/en/latest/reference/examples.html)
- [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)
