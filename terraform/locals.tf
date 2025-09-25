locals {
  cluster_name = "microk8s-homelab"

  # Master nodes configuration
  master_nodes = [
    {
      vm_id      = 301
      name       = "master-1"
      ip_address = "192.168.3.11"
      cpu_cores  = var.master_specs.cpu_cores
      memory     = var.master_specs.memory
    },
    {
      vm_id      = 302
      name       = "master-2"
      ip_address = "192.168.3.12"
      cpu_cores  = var.master_specs.cpu_cores
      memory     = var.master_specs.memory
    }
  ]

  # Worker nodes configuration
  worker_nodes = [
    {
      vm_id      = 303
      name       = "worker-1"
      ip_address = "192.168.3.21"
      cpu_cores  = var.worker_specs.cpu_cores
      memory     = var.worker_specs.memory
    },
    {
      vm_id      = 304
      name       = "worker-2"
      ip_address = "192.168.3.22"
      cpu_cores  = var.worker_specs.cpu_cores
      memory     = var.worker_specs.memory
    },
    {
      vm_id      = 305
      name       = "worker-3"
      ip_address = "192.168.3.23"
      cpu_cores  = var.worker_specs.cpu_cores
      memory     = var.worker_specs.memory
    }
  ]

  # Jumpbox configuration
  jumpbox_config = {
    vm_id     = 399
    name      = "jumpbox-ansible-k8s"
    cpu_cores = 1
    memory    = 512
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
      hosts = merge(
        { for node in local.master_nodes : node.name => node.ip_address },
        { for node in local.worker_nodes : node.name => node.ip_address }
      )
      children = {
        masters = {
          hosts = { for node in local.master_nodes : node.name => {} }
        }
        workers = {
          hosts = { for node in local.worker_nodes : node.name => {} }
        }
      }
    }
  }
}