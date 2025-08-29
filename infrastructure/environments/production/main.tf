locals {
  // Environment-specific VM ID offset to avoid conflicts
  vm_id_offset = 3000 // Production offset for Vault cluster

  // Default CPU type for all VMs
  default_vcpu_type = "host"

  // Vault cluster VM specifications based on requirements doc
  vault_master_spec = {
    vcpu   = 2
    memory = 4096 // 4 GB
    disk   = 40   // 40 GB SSD
  }

  vault_production_spec = {
    vcpu   = 4
    memory = 8192 // 8 GB
    disk   = 100  // 100 GB SSD
  }

  // VM instances for Vault cluster
  vm_instances = {
    vault-master = {
      name        = "vault-master"
      vm_id       = local.vm_id_offset + 100
      ip          = "${var.vault_network_subnet}.30/24"
      gateway     = "${var.vault_network_subnet}.1"
      vcpu        = local.vault_master_spec.vcpu
      vcpu_type   = local.default_vcpu_type
      memory      = local.vault_master_spec.memory
      disk_size   = local.vault_master_spec.disk
      role        = "vault-master"
      description = "Master Vault - Auto-unseal provider with Transit engine"
    }
    vault-prod-1 = {
      name        = "vault-prod-1"
      vm_id       = local.vm_id_offset + 201
      ip          = "${var.vault_network_subnet}.31/24"
      gateway     = "${var.vault_network_subnet}.1"
      vcpu        = local.vault_production_spec.vcpu
      vcpu_type   = local.default_vcpu_type
      memory      = local.vault_production_spec.memory
      disk_size   = local.vault_production_spec.disk
      role        = "vault-production"
      description = "Production Vault Node 1 - Raft cluster member"
    }
    vault-prod-2 = {
      name        = "vault-prod-2"
      vm_id       = local.vm_id_offset + 202
      ip          = "${var.vault_network_subnet}.32/24"
      gateway     = "${var.vault_network_subnet}.1"
      vcpu        = local.vault_production_spec.vcpu
      vcpu_type   = local.default_vcpu_type
      memory      = local.vault_production_spec.memory
      disk_size   = local.vault_production_spec.disk
      role        = "vault-production"
      description = "Production Vault Node 2 - Raft cluster member"
    }
    vault-prod-3 = {
      name        = "vault-prod-3"
      vm_id       = local.vm_id_offset + 203
      ip          = "${var.vault_network_subnet}.33/24"
      gateway     = "${var.vault_network_subnet}.1"
      vcpu        = local.vault_production_spec.vcpu
      vcpu_type   = local.default_vcpu_type
      memory      = local.vault_production_spec.memory
      disk_size   = local.vault_production_spec.disk
      role        = "vault-production"
      description = "Production Vault Node 3 - Raft cluster member"
    }
  }

  env_tag = "production"

  // Node assignments - distribute VMs across Proxmox nodes for HA
  // Master on lloyd, production nodes distributed across holly, mable, lloyd
  node_assignments = {
    vault-master = { node = "lloyd", template_id = var.template_id }
    vault-prod-1 = { node = "holly", template_id = var.template_id }
    vault-prod-2 = { node = "mable", template_id = var.template_id }
    vault-prod-3 = { node = "lloyd", template_id = var.template_id }
  }
}

module "vm" {
  for_each = local.vm_instances

  source = "../../modules/vm"

  // Assign Proxmox node deterministically
  vm_node_name = local.node_assignments[each.key].node

  // Basic VM configuration
  vm_name       = "${each.value.name}-${local.node_assignments[each.key].node}"
  vm_id         = each.value.vm_id
  vm_ip_primary = each.value.ip
  vm_gateway    = each.value.gateway
  vcpu          = each.value.vcpu
  vcpu_type     = each.value.vcpu_type
  memory        = each.value.memory

  // Storage configuration - use specific disk size for each VM
  vm_datastore = var.vm_datastore
  vm_disk_size = each.value.disk_size

  // Network configuration - Single NIC as per requirements
  vm_bridge_1         = var.vm_bridge_1
  vm_bridge_2         = "" // No secondary network for Vault cluster
  enable_dual_network = false
  vm_ip_secondary     = ""

  // Cloud-init configuration
  ci_ssh_key          = var.ci_ssh_key
  template_id         = local.node_assignments[each.key].template_id
  template_node       = var.template_node
  cloud_init_username = var.cloud_init_username
  dns_servers         = var.dns_servers

  // Tags: common, environment, node, and role-specific
  vm_tags = concat(
    var.vm_tags,
    [
      local.env_tag,
      each.value.role,
      local.node_assignments[each.key].node,
      "vault-cluster"
    ]
  )
}
