# Master Nodes
module "master_nodes" {
  source = "../proxmox-vm"

  for_each = { for vm in var.master_nodes : vm.name => vm }

  vm_id         = each.value.vm_id
  vm_name       = each.value.name
  target_node   = var.target_node
  template_id   = var.template_id
  start_on_boot = true
  qemu_agent    = true

  cpu_cores = each.value.cpu_cores
  memory    = each.value.memory

  network_interfaces = [
    {
      bridge = var.cluster_network.bridge
    }
  ]

  ip_configs = [
    {
      ipv4_address = "${each.value.ip_address}${var.cluster_network.cidr_suffix}"
      ipv4_gateway = var.cluster_network.gateway
    }
  ]

  tags = merge(var.common_tags, {
    role    = "master"
    cluster = var.cluster_name
  })
}

# Worker Nodes
module "worker_nodes" {
  source = "../proxmox-vm"

  for_each = { for vm in var.worker_nodes : vm.name => vm }

  vm_id         = each.value.vm_id
  vm_name       = each.value.name
  target_node   = var.target_node
  template_id   = var.template_id
  start_on_boot = true
  qemu_agent    = true

  cpu_cores = each.value.cpu_cores
  memory    = each.value.memory

  network_interfaces = [
    {
      bridge = var.cluster_network.bridge
    }
  ]

  ip_configs = [
    {
      ipv4_address = "${each.value.ip_address}${var.cluster_network.cidr_suffix}"
      ipv4_gateway = var.cluster_network.gateway
    }
  ]

  tags = merge(var.common_tags, {
    role    = "worker"
    cluster = var.cluster_name
  })
}