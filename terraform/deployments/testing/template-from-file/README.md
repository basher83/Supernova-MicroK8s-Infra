# Template Creation from Existing File Example

This example demonstrates creating a Proxmox VM template from a cloud image file that already exists on Proxmox storage. This approach is compatible with existing workflows using manual downloads or the `scripts/build-template.sh` script.

## What This Does

1. **References** an existing cloud image file on Proxmox storage
2. **Creates** a Proxmox VM template from that image
3. **Outputs** the template ID for use in VM cloning operations

## Use Cases

- **Hybrid approach**: Continue using manual downloads while managing templates with Terraform
- **Shell script compatibility**: Works alongside `scripts/build-template.sh`
- **Pre-downloaded images**: When images are downloaded separately (timers, cron jobs)
- **Airgapped environments**: Where Proxmox nodes don't have internet access

## Prerequisites

1. Proxmox VE cluster with API access
2. Cloud image file already present on Proxmox storage
3. `local` datastore enabled for snippets (cloud-init)

## Preparing the Cloud Image

### Option 1: Manual Download

```bash
# SSH to Proxmox node
ssh root@proxmox

# Download Ubuntu cloud image
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Verify
ls -lh ubuntu-22.04-server-cloudimg-amd64.img
```

### Option 2: Using build-template.sh Script

```bash
# Copy image to Proxmox
scp ubuntu-22.04-server-cloudimg-amd64.img root@proxmox:/var/lib/vz/template/iso/

# Or download via script (without creating template)
# Just have the image present for Terraform to use
```

### Option 3: Existing Timer/Cron Job

If you already have automated downloads, ensure the image file exists:

```bash
ssh root@proxmox "ls /var/lib/vz/template/iso/ | grep cloudimg"
```

## Quick Start

### 1. Verify Image Exists

```bash
# Check image is present
ssh root@proxmox "ls -lh /var/lib/vz/template/iso/ubuntu-22.04-server-cloudimg-amd64.img"
```

### 2. Copy Example Configuration

```bash
cd terraform/deployments/examples/template-from-file
cp terraform.tfvars.example terraform.tfvars
```

### 3. Configure Variables

Edit `terraform.tfvars`:

```hcl
proxmox_endpoint      = "https://proxmox.example.com:8006"
proxmox_node          = "lloyd"
template_name         = "ubuntu-22-04-template"
template_id           = 2007
cloud_image_datastore = "local"
cloud_image_filename  = "ubuntu-22.04-server-cloudimg-amd64.img"
```

### 4. Set Proxmox Credentials

```bash
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

# Via Proxmox CLI
ssh root@proxmox "qm list | grep 2007"
```

## Image File Locations

### Standard Proxmox Storage Paths

```bash
# ISO storage (local datastore)
/var/lib/vz/template/iso/

# Common cloud image filenames:
ubuntu-22.04-server-cloudimg-amd64.img
debian-12-generic-amd64.qcow2
rocky-9-cloudimg-amd64.qcow2
```

### Verifying File Location

```bash
# List all cloud images
ssh root@proxmox "ls -lh /var/lib/vz/template/iso/ | grep -E '(img|qcow2)'"

# Check specific file
ssh root@proxmox "stat /var/lib/vz/template/iso/ubuntu-22.04-server-cloudimg-amd64.img"
```

## Hybrid Workflow: Shell Script + Terraform

You can combine existing download scripts with Terraform template management:

### Step 1: Download with Script

```bash
# Use existing script to download images
ssh root@proxmox "/path/to/download-images.sh"
```

### Step 2: Create Template with Terraform

```bash
# Manage template creation with Terraform
cd terraform/deployments/examples/template-from-file
tofu apply
```

**Benefits**:

- ✅ Keep existing download automation
- ✅ Gain Terraform template management
- ✅ Gradual migration path
- ✅ Version controlled template configuration

## Template Configuration

The template is created with:

- **BIOS**: UEFI (ovmf)
- **Machine**: q35
- **CPU**: 2 cores (host passthrough)
- **Memory**: 2048 MB
- **Disk**: 32 GB (resizable during clone)
- **Network**: Single NIC, DHCP

Customize in `main.tf` as needed.

## Using the Template

Once created, use the template for cloning:

### With Single VM Example

```hcl
# In terraform/deployments/examples/single-vm/main.tf
module "my_vm" {
  source = "../../../modules/vm"

  vm_type = "clone"
  src_clone = {
    datastore_id = "local-lvm"
    tpl_id       = 2007  # From this template
  }
  # ...
}
```

### With VM Cluster Example

```hcl
# In terraform/deployments/examples/microk8s-cluster/main.tf
module "cluster" {
  source = "../../../modules/vm-cluster"

  template_id = 2007  # From this template
  # ...
}
```

## Comparison with template-from-url

| Feature               | template-from-file  | template-from-url         |
| --------------------- | ------------------- | ------------------------- |
| Image download        | Manual/External     | Automated by Terraform    |
| Internet required     | No (pre-downloaded) | Yes (during apply)        |
| Airgap friendly       | ✅ Yes              | ❌ No                     |
| Existing workflows    | ✅ Compatible       | Replaces workflows        |
| Checksum verification | Manual              | Automated                 |
| Best for              | Hybrid migrations   | Full Terraform automation |

## Troubleshooting

### Image File Not Found

**Error**: `Error creating VM: file not found`

**Solution**:

1. Verify file exists: `ssh root@proxmox "ls -lh /var/lib/vz/template/iso/<filename>"`
2. Check filename in `terraform.tfvars` matches exactly
3. Ensure `cloud_image_datastore = "local"` (not "local-lvm")

### Wrong Datastore

**Error**: `datastore 'local-lvm' does not support 'iso' content type`

**Solution**:

- Cloud images must be in `local` datastore (ISO storage)
- VM disks use `local-lvm` datastore
- Set `cloud_image_datastore = "local"` in terraform.tfvars

### Permission Denied

**Error**: `Permission denied accessing image file`

**Solution**:

```bash
# Fix file permissions
ssh root@proxmox "chmod 644 /var/lib/vz/template/iso/<filename>"
```

## Migration Path

### Current State: Shell Script Only

```bash
# Current: Manual process
scripts/build-template.sh --img /var/lib/vz/template/iso/ubuntu.img ...
```

### Intermediate: Hybrid Approach

```bash
# Download externally
wget https://cloud-images.ubuntu.com/... -O /var/lib/vz/template/iso/ubuntu.img

# Create template with Terraform
cd terraform/deployments/examples/template-from-file
tofu apply
```

### Future State: Fully Automated

```bash
# Everything in Terraform
cd terraform/deployments/examples/template-from-url
tofu apply
```

## Related Examples

- **[template-from-url](../template-from-url/)** - Automated image download and template creation
- **[single-vm](../single-vm/)** - Clone VMs from this template
- **[microk8s-cluster](../microk8s-cluster/)** - Deploy clusters using this template

## Additional Resources

- [Proxmox VM Provisioning Guide](../../../../docs/terraform/proxmox-vm-provisioning-guide.md)
- [VM Module Documentation](../../../modules/vm/README.md)
- [build-template.sh Script](../../../../scripts/build-template.sh)
