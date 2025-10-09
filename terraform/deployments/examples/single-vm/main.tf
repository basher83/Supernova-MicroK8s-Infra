# =============================================================================
# = Single VM Deployment Example =============================================
# =============================================================================
# This example demonstrates deploying a single VM using the vm module with
# the template-clone approach. Perfect for application servers, databases,
# development environments, or any single-VM workload.

terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      version = ">= 0.84.1"
      source  = "bpg/proxmox"
    }
  }
}

# Configure the Proxmox provider
provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure

  # Authentication handled via environment variables or API token
  # PROXMOX_VE_USERNAME, PROXMOX_VE_PASSWORD
  # or PROXMOX_VE_API_TOKEN
}

# =============================================================================
# = Single VM Deployment ======================================================
# =============================================================================

module "single_vm" {
  source = "../../../modules/vm"

  # VM Type - using template clone for fast deployment
  vm_type  = "clone"
  pve_node = var.proxmox_node

  # Clone from existing template
  src_clone = {
    datastore_id = var.datastore
    tpl_id       = var.template_id
  }

  # VM Identification
  vm_name        = var.vm_name
  vm_id          = var.vm_id
  vm_description = var.vm_description
  vm_tags        = var.vm_tags

  # Hardware Configuration
  vm_bios    = "ovmf"
  vm_machine = "q35"
  vm_os      = "l26"

  vm_cpu = {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  vm_mem = {
    dedicated = var.memory
  }

  # QEMU Guest Agent (enabled for IP retrieval and graceful shutdown)
  vm_agent = {
    enabled = true
    timeout = "15m"
    trim    = true # Enable fstrim for cloned disks
  }

  # Random Number Generator (for entropy)
  vm_rng = {
    source = "/dev/urandom"
  }

  # Serial Console
  vm_serial = {
    serial0 = {
      device = "socket"
    }
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

  # Disk Configuration
  vm_disk = {
    scsi0 = {
      datastore_id = var.datastore
      size         = var.disk_size
      file_format  = "raw"
      iothread     = true
      ssd          = true
      discard      = "on"
      main_disk    = true
    }
  }

  # Network Configuration - Dual NIC setup (conditionally add net1)
  vm_net_ifaces = merge(
    {
      net0 = {
        bridge    = var.network_bridge
        vlan_id   = var.vlan_id
        firewall  = false
        ipv4_addr = "${var.ip_address}/${var.network_cidr}"
        ipv4_gw   = var.network_gateway
      }
    },
    var.enable_secondary_nic ? {
      net1 = {
        bridge    = var.network_bridge_secondary
        vlan_id   = var.vlan_id_secondary
        firewall  = false
        ipv4_addr = "${var.ip_address_secondary}/${var.network_cidr_secondary}"
        ipv4_gw   = null # Secondary NIC doesn't need a gateway
      }
    } : {}
  )

  # Cloud-init Configuration
  vm_init = {
    datastore_id = "local"
    interface    = "ide0"

    dns = {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    user = {
      name = var.vm_username
      keys = var.ssh_public_keys
    }
  }

  # VM Start Settings
  vm_start = {
    on_deploy  = var.start_on_deploy
    on_boot    = var.start_on_boot
    order      = var.boot_order
    up_delay   = var.boot_up_delay
    down_delay = var.boot_down_delay
  }
}
