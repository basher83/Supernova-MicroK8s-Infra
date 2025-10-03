# Create vendor data snippet to install qemu-guest-agent
resource "proxmox_virtual_environment_file" "vendor_data" {
  count = var.cloud_init_enabled ? 1 : 0

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.target_node

  source_raw {
    file_name = "microk8s-vendor-${var.vm_id}.yaml"
    data      = <<-EOF
#cloud-config
packages:
  - qemu-guest-agent
package_update: true

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
    EOF
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  vm_id       = var.vm_id
  name        = var.vm_name
  node_name   = var.target_node
  description = var.vm_description
  on_boot     = var.start_on_boot
  tags        = var.tags

  machine = var.machine_type
  bios    = var.bios_type

  clone {
    vm_id        = var.template_id
    node_name    = var.template_node
    full         = true
    datastore_id = var.disk_datastore_id
  }

  # Ensure template is available on target node by waiting for it
  # This addresses the cross-node template availability issue

  agent {
    enabled = var.qemu_agent
    timeout = "5m"
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
      file_format  = "raw"
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

      user_data_file_id   = var.user_data_file_id
      vendor_data_file_id = var.cloud_init_enabled ? proxmox_virtual_environment_file.vendor_data[0].id : null
    }
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
      initialization[0].vendor_data_file_id
    ]
  }
}
