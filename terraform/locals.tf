locals {
  cluster_name = "microk8s-homelab"

  # VM specifications based on role
  microk8s_node_spec = {
    cpu_cores = var.node_specs.cpu_cores
    memory    = var.node_specs.memory
    disk_size = var.disk_size
  }

  jumpbox_spec = {
    cpu_cores = 1
    memory    = 512
    disk_size = 20
  }

  # VM instances with their configurations
  vm_instances = {
    jumpbox = {
      name         = "jumpbox-ansible-k8s"
      vm_id        = 399
      ip           = var.jumpbox_home_ip
      gateway      = var.home_network.gateway
      cpu_cores    = local.jumpbox_spec.cpu_cores
      memory       = local.jumpbox_spec.memory
      disk_size    = local.jumpbox_spec.disk_size
      role         = "jumpbox"
      description  = "Bastion host with dual-network access for cluster management"
      dual_network = true
      cluster_ip   = var.jumpbox_cluster_ip
    }
    microk8s-1 = {
      name         = "microk8s-1"
      vm_id        = 311
      ip           = "192.168.4.11/24"
      gateway      = var.cluster_network.gateway
      cpu_cores    = local.microk8s_node_spec.cpu_cores
      memory       = local.microk8s_node_spec.memory
      disk_size    = local.microk8s_node_spec.disk_size
      role         = "microk8s-node"
      description  = "MicroK8s cluster node 1"
      dual_network = false
      cluster_ip   = ""
    }
    microk8s-2 = {
      name         = "microk8s-2"
      vm_id        = 312
      ip           = "192.168.4.12/24"
      gateway      = var.cluster_network.gateway
      cpu_cores    = local.microk8s_node_spec.cpu_cores
      memory       = local.microk8s_node_spec.memory
      disk_size    = local.microk8s_node_spec.disk_size
      role         = "microk8s-node"
      description  = "MicroK8s cluster node 2"
      dual_network = false
      cluster_ip   = ""
    }
    microk8s-3 = {
      name         = "microk8s-3"
      vm_id        = 313
      ip           = "192.168.4.13/24"
      gateway      = var.cluster_network.gateway
      cpu_cores    = local.microk8s_node_spec.cpu_cores
      memory       = local.microk8s_node_spec.memory
      disk_size    = local.microk8s_node_spec.disk_size
      role         = "microk8s-node"
      description  = "MicroK8s cluster node 3"
      dual_network = false
      cluster_ip   = ""
    }
  }

  # Node assignments - distribute VMs across Proxmox nodes
  # NOTE: Template VM 7024 currently only exists on 'lloyd'
  # For multi-node deployment, copy template to target nodes first
  node_assignments = {
    jumpbox    = { node = "lloyd", template_id = var.template_id }
    microk8s-1 = { node = "lloyd", template_id = var.template_id }
    microk8s-2 = { node = "lloyd", template_id = var.template_id }
    microk8s-3 = { node = "lloyd", template_id = var.template_id }
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
      hosts = {
        for name, config in local.vm_instances :
        name => split("/", config.ip)[0]
      }
      children = {
        microk8s = {
          hosts = {
            for name, config in local.vm_instances :
            name => {}
            if config.role == "microk8s-node"
          }
        }
        jumpbox = {
          hosts = {
            for name, config in local.vm_instances :
            name => {}
            if config.role == "jumpbox"
          }
        }
      }
    }
  }
}
