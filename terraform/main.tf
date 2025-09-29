# Unified VM Deployment
# Create all VMs using dynamic module creation with proper node assignment
module "vm" {
  for_each = local.vm_instances

  source = "./modules/proxmox-vm"

  # Assign Proxmox node deterministically based on node_assignments
  vm_id           = each.value.vm_id
  vm_name         = each.value.name
  target_node     = local.node_assignments[each.key].node
  template_id     = local.node_assignments[each.key].template_id

  # VM specifications
  cpu_cores       = each.value.cpu_cores
  memory          = each.value.memory
  machine_type    = var.machine_type
  bios_type       = var.bios_type
  efi_disk_enabled = var.efi_disk_enabled
  vm_description  = each.value.description
  disk_datastore_id = var.disk_datastore_id
  disk_size       = each.value.disk_size
  disk_iothread   = var.disk_iothread
  disk_discard    = var.disk_discard

  # Network configuration
  network_interfaces = each.value.dual_network ? [
    {
      bridge = var.home_network.bridge
      model  = "virtio"
    },
    {
      bridge = var.cluster_network.bridge
      model  = "virtio"
    }
  ] : [
    {
      bridge = var.cluster_network.bridge
      model  = "virtio"
    }
  ]

  cloud_init_enabled = true
  ip_configs = each.value.dual_network ? [
    {
      ipv4_address = each.value.ip
      ipv4_gateway = each.value.gateway
    },
    {
      ipv4_address = "${each.value.cluster_ip}${var.cluster_network.cidr_suffix}"
      ipv4_gateway = var.cluster_network.gateway
    }
  ] : [
    {
      ipv4_address = each.value.ip
      ipv4_gateway = each.value.gateway
    }
  ]

  tags = merge(local.common_tags, {
    role = each.value.role
    node = local.node_assignments[each.key].node
  })
}
