resource "proxmox_virtual_environment_vm" "vm" {
  vm_id       = var.vm_id
  name        = var.vm_name
  node_name   = var.target_node
  description = var.vm_description
  on_boot     = var.start_on_boot

  machine = var.machine_type
  bios    = var.bios_type

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = var.qemu_agent
  }

  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory
  }

  boot_order = var.boot_order

  # Serial device required for Debian 12 / Ubuntu VMs to prevent kernel panic during boot disk resize
  serial_device {
    device = "socket"
  }

  # EFI disk for UEFI boot support
  dynamic "efi_disk" {
    for_each = var.efi_disk_enabled ? [1] : []
    content {
      datastore_id = var.disk_datastore_id
      type         = "4m"
    }
  }

  disk {
    datastore_id = var.disk_datastore_id
    interface    = "virtio0"
    iothread     = var.disk_iothread
    discard      = var.disk_discard
    size         = var.disk_size
  }

  dynamic "network_device" {
    for_each = var.network_interfaces
    content {
      bridge = network_device.value.bridge
      model  = lookup(network_device.value, "model", "virtio")
    }
  }

  dynamic "initialization" {
    for_each = var.cloud_init_enabled ? [1] : []
    content {
      dynamic "ip_config" {
        for_each = var.ip_configs
        content {
          ipv4 {
            address = ip_config.value.ipv4_address
            gateway = lookup(ip_config.value, "ipv4_gateway", null)
          }
          ipv6 {
            address = lookup(ip_config.value, "ipv6_address", null)
            gateway = lookup(ip_config.value, "ipv6_gateway", null)
          }
        }
      }

      user_data_file_id = var.user_data_file_id
    }
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id
    ]
  }
}
