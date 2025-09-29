locals {
  cluster_name = "microk8s-homelab"

  # MicroK8s nodes configuration (all nodes participate equally)
  microk8s_nodes = [
    {
      vm_id       = 311
      name        = "microk8s-1"
      ip_address  = "192.168.4.11"
      target_node = var.target_node_1
      cpu_cores   = var.node_specs.cpu_cores
      memory      = var.node_specs.memory
    },
    {
      vm_id       = 312
      name        = "microk8s-2"
      ip_address  = "192.168.4.12"
      target_node = var.target_node_2
      cpu_cores   = var.node_specs.cpu_cores
      memory      = var.node_specs.memory
    },
    {
      vm_id       = 313
      name        = "microk8s-3"
      ip_address  = "192.168.4.13"
      target_node = var.target_node_3
      cpu_cores   = var.node_specs.cpu_cores
      memory      = var.node_specs.memory
    }
  ]

  # Jumpbox configuration
  jumpbox_config = {
    vm_id       = 399
    name        = "jumpbox-ansible-k8s"
    target_node = var.target_node_1 # Deploy jumpbox on first node
    cpu_cores   = 1
    memory      = 512
  }

  # Common tags for all resources
  common_tags = {
    environment = var.environment
    project     = "supernova-microk8s"
    managed_by  = "terraform"
    created_at  = timestamp()
  }

  # Ansible inventory for output
  ansible_inventory = {
    all = {
      hosts = { for node in local.microk8s_nodes : node.name => node.ip_address }
      children = {
        microk8s = {
          hosts = { for node in local.microk8s_nodes : node.name => {} }
        }
      }
    }
  }
}
