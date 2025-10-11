# =============================================================================
# = Template with Custom Cloud-Init Example ===================================
# =============================================================================
# This example demonstrates creating a Proxmox VM template with custom
# cloud-init user-data configuration by:
# 1. Uploading custom user-data.yaml to Proxmox
# 2. Downloading cloud image from URL
# 3. Creating template with custom cloud-init configuration
#
# Resources Used:
# - proxmox_virtual_environment_file (upload user-data)
# - proxmox_virtual_environment_download_file (download cloud image - via module)
# - proxmox_virtual_environment_vm (create template - via module)
#
# IMPORTANT: Template creation requires SSH access to the Proxmox host.
# See provider.tf for SSH configuration details.

# =============================================================================
# = Upload Custom Cloud-Init User-Data ========================================
# =============================================================================

resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  content_type = "snippets"
  datastore_id = var.cloud_init_datastore
  node_name    = var.proxmox_node

  source_file {
    path      = var.user_data_file
    file_name = var.user_data_snippet_name
  }
}

# =============================================================================
# = Template Creation with Custom Cloud-Init ==================================
# =============================================================================

module "ubuntu_template" {
  source = "../../../modules/vm"

  # VM Type - using 'image' type with URL download
  vm_type  = "image"
  pve_node = var.proxmox_node

  # Mark as template (cannot be started, used for cloning)
  vm_template = true

  # Cloud image download configuration
  # NOTE: cloud_image_datastore must be file-based storage (e.g., 'local')
  # Cannot use block-based storage like 'local-lvm'
  src_file = {
    url          = var.cloud_image_url
    datastore_id = var.cloud_image_datastore
    file_name    = var.cloud_image_filename
    checksum     = var.cloud_image_checksum # Optional but recommended
  }

  # VM Identification
  vm_name        = var.template_name
  vm_id          = var.template_id
  vm_description = var.template_description
  vm_tags        = var.template_tags

  # Hardware Configuration
  vm_bios    = var.vm_bios
  vm_machine = var.vm_machine
  vm_os      = var.vm_os

  vm_cpu = {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  vm_mem = {
    dedicated = var.memory
  }

  # QEMU Guest Agent
  vm_agent = {
    enabled = var.qemu_agent_enabled
    timeout = var.qemu_agent_timeout
    trim    = var.qemu_agent_trim
  }

  # EFI Disk (required for UEFI boot)
  vm_efi_disk = {
    datastore_id = var.datastore
    file_format  = var.efi_disk_format
    type         = var.efi_disk_type
  }

  # Disk Configuration (will be imported from cloud image)
  vm_disk = {
    scsi0 = {
      datastore_id = var.datastore
      size         = var.disk_size
      file_format  = var.disk_file_format
      iothread     = var.disk_iothread
      ssd          = var.disk_ssd
      discard      = var.disk_discard
      main_disk    = true
    }
  }

  # Network Configuration (minimal, will be configured during clone)
  vm_net_ifaces = {
    net0 = {
      bridge    = var.network_bridge
      firewall  = var.network_firewall
      ipv4_addr = "dhcp"
    }
  }

  # Cloud-init Configuration with Custom User-Data
  vm_init = {
    datastore_id = var.cloud_init_datastore
    interface    = var.cloud_init_interface

    dns = {
      servers = var.dns_servers
    }

    # Note: vm_init.user is NOT set because we're using custom user_data
    # Setting both would cause a validation error
  }

  # Reference the uploaded custom user-data file
  vm_user_data = proxmox_virtual_environment_file.cloud_init_user_data.id

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

output "cloud_init_file_id" {
  description = "Cloud-init user-data file ID in Proxmox"
  value       = proxmox_virtual_environment_file.cloud_init_user_data.id
}
