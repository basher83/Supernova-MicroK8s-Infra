# =============================================================================
# = Template Creation from Existing File Example ==============================
# =============================================================================
# This example demonstrates creating a Proxmox VM template from an existing
# cloud image file already present on the Proxmox storage.
#
# Features:
# - Uses pre-downloaded cloud images
# - Template creation with minimal configuration
# - Compatible with shell script workflows (build-template.sh)
#
# Use Case: When images are managed outside Terraform (manual downloads, timers)
#
# IMPORTANT: Template creation requires SSH access to the Proxmox host.
# See provider.tf for SSH configuration details.

# =============================================================================
# = Template Creation from Existing File ======================================
# =============================================================================

module "ubuntu_template" {
  source = "../../../modules/vm"

  # VM Type - using 'image' type with existing file
  vm_type  = "image"
  pve_node = var.proxmox_node

  # Mark as template (cannot be started, used for cloning)
  vm_template = true

  # Reference existing cloud image file
  # File must already exist on Proxmox storage
  src_file = {
    datastore_id = var.cloud_image_datastore
    file_name    = var.cloud_image_filename
    # No URL - file already exists on Proxmox
  }

  # VM Identification
  vm_name = var.template_name
  vm_id   = var.template_id
  # Note: Avoid timestamp() in descriptions - causes constant drift on every plan
  vm_description = "Ubuntu 22.04 LTS Cloud Template"
  vm_tags        = ["template", "ubuntu", "cloud-init"]

  # Hardware Configuration (minimal for template)
  vm_bios    = "ovmf"
  vm_machine = "q35"
  vm_os      = "l26"

  vm_cpu = {
    cores = 2
    type  = "host"
  }

  vm_mem = {
    dedicated = 2048
  }

  # QEMU Guest Agent (essential for cloned VMs)
  vm_agent = {
    enabled = true
    timeout = "15m"
    trim    = true
  }

  # Display Configuration
  vm_display = {
    type   = "serial0"
    memory = 16
  }

  # EFI Disk (required for UEFI boot)
  vm_efi_disk = {
    datastore_id = var.datastore
    file_format  = "raw"
    type         = "4m"
  }

  # Disk Configuration (will be imported from cloud image)
  vm_disk = {
    scsi0 = {
      datastore_id = var.datastore
      size         = 32 # Cloud image will be resized to this
      file_format  = "raw"
      iothread     = true
      ssd          = true
      discard      = "on"
      main_disk    = true
    }
  }

  # Network Configuration (minimal, will be configured during clone)
  vm_net_ifaces = {
    net0 = {
      bridge    = var.network_bridge
      firewall  = false
      ipv4_addr = "dhcp"
    }
  }

  # Cloud-init Configuration
  vm_init = {
    datastore_id = "local"
    interface    = "ide0"

    dns = {
      servers = ["1.1.1.1", "8.8.8.8"]
    }

    # Note: User configuration not needed for template
    # It will be set during cloning
  }

  # VM Start Settings (templates don't start)
  vm_start = {
    on_deploy  = false
    on_boot    = false
    order      = 0
    up_delay   = 0
    down_delay = 0
  }
}

# =============================================================================
# = Outputs ===================================================================
# =============================================================================

output "template_id" {
  description = "Template VM ID for use in clone operations"
  value       = module.ubuntu_template.vm_id
}

output "template_name" {
  description = "Template VM name"
  value       = module.ubuntu_template.vm_name
}

output "template_node" {
  description = "Proxmox node where template is stored"
  value       = module.ubuntu_template.vm_node
}
