# MicroK8s Kubernetes Cluster
module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  cluster_name    = local.cluster_name
  target_node     = var.target_node
  template_id     = var.template_id

  master_nodes    = local.master_nodes
  worker_nodes    = local.worker_nodes
  cluster_network = var.cluster_network

  common_tags = local.common_tags
}

# Jumpbox / Bastion Host
module "jumpbox" {
  source = "./modules/jumpbox"

  vm_id              = local.jumpbox_config.vm_id
  vm_name            = local.jumpbox_config.name
  target_node        = var.target_node
  template_id        = var.template_id

  cpu_cores          = local.jumpbox_config.cpu_cores
  memory             = local.jumpbox_config.memory

  home_network       = var.home_network
  home_network_ip    = var.jumpbox_home_ip
  cluster_network    = var.cluster_network
  cluster_network_ip = var.jumpbox_cluster_ip

  common_tags = local.common_tags
}