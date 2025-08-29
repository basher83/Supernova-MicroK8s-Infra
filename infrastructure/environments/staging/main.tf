terraform {
  required_version = ">= 1.3.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.73.2"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pve_api_url
  api_token = var.pve_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    username = var.proxmox_ssh_username
  }
}
locals {
  // Environment-specific VM ID offset to avoid conflicts
  vm_id_offset = 3000 // Staging offset


  default_vm = {
    vcpu      = 4
    vcpu_type = "host"
  }

  // Merge defaults with each VM's configuration.
  vm_instances = {
    nomad-server-1 = merge(local.default_vm, {
      name    = "nomad-server-1"
      vm_id   = local.vm_id_offset + 101
      ip      = "192.168.10.11/24"
      gateway = "192.168.10.1"
      ip2     = "192.168.11.11/24"
      role    = "server"
    })
    nomad-server-2 = merge(local.default_vm, {
      name    = "nomad-server-2"
      vm_id   = local.vm_id_offset + 102
      ip      = "192.168.10.12/24"
      gateway = "192.168.10.1"
      ip2     = "192.168.11.12/24"
      role    = "server"
    })
    nomad-server-3 = merge(local.default_vm, {
      name    = "nomad-server-3"
      vm_id   = local.vm_id_offset + 103
      ip      = "192.168.10.13/24"
      gateway = "192.168.10.1"
      ip2     = "192.168.11.13/24"
      role    = "server"
    })
    nomad-client-1 = merge(local.default_vm, {
      name    = "nomad-client-1"
      vm_id   = local.vm_id_offset + 510
      ip      = "192.168.10.20/24"
      gateway = "192.168.10.1"
      ip2     = "192.168.11.20/24"
      vcpu    = 8
      role    = "client"
    })
    nomad-client-2 = merge(local.default_vm, {
      name    = "nomad-client-2"
      vm_id   = local.vm_id_offset + 511
      ip      = "192.168.10.21/24"
      gateway = "192.168.10.1"
      ip2     = "192.168.11.21/24"
      vcpu    = 8
      role    = "client"
    })
    nomad-client-3 = merge(local.default_vm, {
      name    = "nomad-client-3"
      vm_id   = local.vm_id_offset + 512
      ip      = "192.168.10.22/24"
      gateway = "192.168.10.1"
      ip2     = "192.168.11.22/24"
      vcpu    = 8
      role    = "client"
    })
  }

  env_tag = "staging"
  node_assignments = {
    nomad-server-1 = { node = "lloyd", template_id = 9101 }
    nomad-server-2 = { node = "holly", template_id = 9102 }
    nomad-server-3 = { node = "mable", template_id = 9103 }
    nomad-client-1 = { node = "lloyd", template_id = 9101 }
    nomad-client-2 = { node = "holly", template_id = 9102 }
    nomad-client-3 = { node = "mable", template_id = 9103 }
  }
}

module "vm" {
  for_each = local.vm_instances

  source = "../../modules/vm"


  // Assign Proxmox node deterministically
  vm_node_name = local.node_assignments[each.key].node

  // Basic VM configuration
  vm_name         = "${each.value.name}-${local.node_assignments[each.key].node}"
  vm_id           = each.value.vm_id
  vm_ip_primary   = each.value.ip
  vm_gateway      = each.value.gateway
  vm_ip_secondary = each.value.ip2
  vcpu            = each.value.vcpu
  vcpu_type       = each.value.vcpu_type

  // Infrastructure values from variables
  vm_datastore        = var.vm_datastore
  vm_disk_size        = var.vm_disk_size
  vm_bridge_1         = var.vm_bridge_1
  vm_bridge_2         = var.vm_bridge_2
  ci_ssh_key          = var.ci_ssh_key
  template_id         = local.node_assignments[each.key].template_id
  cloud_init_username = var.cloud_init_username

  // Tags: common, environment, node, and role-specific
  vm_tags = concat(
    var.vm_tags,
    [
      local.env_tag,
      each.value.role,
      local.node_assignments[each.key].node
    ]
  )
}
