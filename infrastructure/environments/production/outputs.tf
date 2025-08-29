# --- Outputs for Vault cluster production environment ---

output "vault_master" {
  value = {
    name    = module.vm["vault-master"].vm_name
    id      = module.vm["vault-master"].vm_id
    ip      = module.vm["vault-master"].primary_ip
    node    = local.node_assignments["vault-master"].node
    api_url = "https://${module.vm["vault-master"].primary_ip}:8200"
  }
  description = "Master Vault VM details for auto-unseal provider"
}

output "vault_production_nodes" {
  value = {
    for k, v in module.vm : k => {
      name    = v.vm_name
      id      = v.vm_id
      ip      = v.primary_ip
      node    = local.node_assignments[k].node
      api_url = "https://${v.primary_ip}:8200"
    } if startswith(k, "vault-prod")
  }
  description = "Production Vault cluster nodes details"
}

output "vault_cluster_summary" {
  value = {
    master_api_endpoint = "https://${module.vm["vault-master"].primary_ip}:8200"
    production_api_endpoints = [
      for k, v in module.vm : "https://${v.primary_ip}:8200"
      if startswith(k, "vault-prod")
    ]
    raft_cluster_port = 8201
    total_vcpus       = sum([for vm in local.vm_instances : vm.vcpu])
    total_memory_gb   = sum([for vm in local.vm_instances : vm.memory]) / 1024
    total_storage_gb  = sum([for vm in local.vm_instances : vm.disk_size])
  }
  description = "Vault cluster configuration summary"
}

output "network_configuration" {
  value = {
    subnet    = var.vault_network_subnet
    gateway   = "${var.vault_network_subnet}.1"
    master_ip = "${var.vault_network_subnet}.30"
    production_ips = [
      "${var.vault_network_subnet}.31",
      "${var.vault_network_subnet}.32",
      "${var.vault_network_subnet}.33"
    ]
  }
  description = "Network configuration for the Vault cluster"
}

output "ansible_yaml_inventory" {
  value = yamlencode({
    all = {
      children = {
        vault_master = {
          hosts = {
            (module.vm["vault-master"].vm_name) = {
              ansible_host = module.vm["vault-master"].primary_ip
              vault_role   = "master"
            }
          }
        }
        vault_production = {
          hosts = {
            for k, v in module.vm :
            v.vm_name => {
              ansible_host = v.primary_ip
              vault_role   = "production"
            } if startswith(k, "vault-prod")
          }
        }
      }
    }
  })
  description = "Ansible inventory in YAML format for Vault cluster configuration"
}
