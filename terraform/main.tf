# Jumpbox / Bastion Host
module "jumpbox" {
  source = "./modules/jumpbox"

  vm_id       = local.jumpbox_config.vm_id
  vm_name     = local.jumpbox_config.name
  target_node = local.jumpbox_config.target_node
  template_id = var.template_id

  cpu_cores = local.jumpbox_config.cpu_cores
  memory    = local.jumpbox_config.memory

  home_network       = var.home_network
  home_network_ip    = var.jumpbox_home_ip
  cluster_network    = var.cluster_network
  cluster_network_ip = var.jumpbox_cluster_ip

  common_tags = local.common_tags
}

# MicroK8s Cluster Nodes
# Create 3 identical MicroK8s nodes that will form the cluster
module "microk8s_nodes" {
  source   = "./modules/proxmox-vm"
  for_each = { for node in local.microk8s_nodes : node.name => node }

  vm_id       = each.value.vm_id
  vm_name     = each.value.name
  target_node = each.value.target_node
  template_id = var.template_id

  cpu_cores = each.value.cpu_cores
  memory    = each.value.memory

  network_interfaces = [
    {
      bridge = var.cluster_network.bridge
      model  = "virtio"
    }
  ]

  cloud_init_enabled = true
  ip_configs = [
    {
      ipv4_address = "${each.value.ip_address}${var.cluster_network.cidr_suffix}"
      ipv4_gateway = var.cluster_network.gateway
    }
  ]

  tags = local.common_tags
}
