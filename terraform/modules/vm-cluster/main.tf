# Copyright 2025 RalZareck
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# =============================================================================
# = VM Cluster Module =========================================================
# =============================================================================
# This module is a wrapper around the vm/ module that simplifies deployment
# of multiple VMs with similar configurations using for_each.
# Perfect for Kubernetes clusters, application clusters, or any multi-VM setup.

module "cluster_vms" {
  source   = "../vm"
  for_each = var.nodes

  # Node identification
  vm_type  = "clone"
  pve_node = each.value.pve_node
  vm_name  = each.key
  vm_id    = each.value.vm_id
  vm_tags  = concat(var.cluster_tags, each.value.tags != null ? each.value.tags : [])

  # Clone configuration (always uses template-clone approach for clusters)
  src_clone = {
    datastore_id = var.template_datastore
    node_name    = each.value.template_node != null ? each.value.template_node : var.template_node
    tpl_id       = var.template_id
  }

  # Hardware configuration
  vm_bios    = var.vm_bios
  vm_machine = var.vm_machine
  vm_os      = var.vm_os

  vm_cpu = {
    cores = each.value.cpu_cores != null ? each.value.cpu_cores : var.default_cpu_cores
    type  = var.cpu_type
    units = null # Not configurable per-node
  }

  vm_mem = {
    dedicated = each.value.memory != null ? each.value.memory : var.default_memory
    floating  = null # Not configurable per-node
    shared    = null # Not configurable per-node
  }

  # Agent configuration (enabled by default for cluster VMs)
  vm_agent = var.vm_agent

  # Display configuration
  vm_display = var.vm_display

  # EFI disk for UEFI boot
  vm_efi_disk = var.vm_bios == "ovmf" ? {
    datastore_id      = each.value.efi_datastore != null ? each.value.efi_datastore : var.template_datastore
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  } : null

  # Disk configuration
  vm_disk = {
    for disk_key, disk_config in var.disk_configuration : disk_key => {
      datastore_id = each.value.disk_datastore != null ? each.value.disk_datastore : var.template_datastore
      size         = each.value.disk_size != null ? each.value.disk_size : disk_config.size
      file_format  = disk_config.file_format
      iothread     = disk_config.iothread
      ssd          = disk_config.ssd
      discard      = disk_config.discard
      main_disk    = disk_config.main_disk
    }
  }

  # Network configuration - supports multiple NICs
  vm_net_ifaces = {
    for net_key, net_config in var.network_interfaces : net_key => {
      bridge     = each.value.network_bridge != null ? each.value.network_bridge : net_config.bridge
      enabled    = true
      firewall   = net_config.firewall != null ? net_config.firewall : false
      mac_addr   = each.value.mac_address
      model      = net_config.model != null ? net_config.model : "virtio"
      mtu        = net_config.mtu != null ? net_config.mtu : 1500
      rate_limit = net_config.rate_limit
      vlan_id    = each.value.vlan_id != null ? each.value.vlan_id : net_config.vlan_id
      # Primary NIC (net0) gets ip_address, secondary NICs get ip_address_secondary or dhcp
      ipv4_addr = net_key == "net0" ? "${each.value.ip_address}/${var.network_cidr}" : (
        net_key == "net1" && each.value.ip_address_secondary != null ? "${each.value.ip_address_secondary}/${var.network_cidr}" : "dhcp"
      )
      # Only primary NIC gets gateway
      ipv4_gw = net_key == "net0" ? var.network_gateway : null
    }
  }

  # Cloud-init configuration
  vm_init = merge(
    var.cloud_init_config,
    {
      datastore_id = var.cloud_init_config.datastore_id
      interface    = var.cloud_init_config.interface
    }
  )

  # Use custom cloud-init user data if provided
  vm_user_data = each.value.user_data_file_id != null ? each.value.user_data_file_id : var.custom_user_data_file_id

  # VM start settings
  vm_start = {
    on_deploy  = var.start_on_deploy
    on_boot    = var.start_on_boot
    order      = each.value.boot_order != null ? each.value.boot_order : 0
    up_delay   = var.boot_up_delay
    down_delay = var.boot_down_delay
  }
}
