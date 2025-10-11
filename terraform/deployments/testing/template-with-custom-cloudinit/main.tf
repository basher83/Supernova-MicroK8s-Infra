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
#
# This example follows DRY principles by:
# - Only specifying template-specific overrides and custom user-data
# - Not repeating module defaults (see terraform/modules/vm/DEFAULTS.md)
# - Keeping configuration minimal - templates are refined during cloning

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
  source      = "../../../modules/vm"
  vm_type     = "image"
  pve_node    = var.proxmox_node
  vm_template = true
  src_file = {
    url          = var.cloud_image_url
    datastore_id = var.cloud_image_datastore
    file_name    = var.cloud_image_filename
    checksum     = var.cloud_image_checksum # Optional but recommended
  }

  vm_name        = var.template_name
  vm_id          = var.template_id
  vm_description = var.template_description
  vm_tags        = var.template_tags
  vm_efi_disk = {
    datastore_id = var.datastore
  }

  vm_disk = {
    scsi0 = {
      datastore_id = var.datastore
      size         = var.disk_size
      main_disk    = true
    }
  }

  vm_net_ifaces = {
    net0 = {
      bridge    = var.network_bridge
      ipv4_addr = "dhcp"
    }
  }

  vm_init = {
    datastore_id = var.cloud_init_datastore
    dns = {
      servers = var.dns_servers
    }
  }

  vm_user_data = proxmox_virtual_environment_file.cloud_init_user_data.id

  vm_start = {
    on_deploy = false
    on_boot   = false
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
