output "master_nodes" {
  description = "Master node details"
  value = {
    for name, node in module.master_nodes : name => {
      vm_id        = node.vm_id
      vm_name      = node.vm_name
      ip_addresses = node.ip_addresses
    }
  }
}

output "worker_nodes" {
  description = "Worker node details"
  value = {
    for name, node in module.worker_nodes : name => {
      vm_id        = node.vm_id
      vm_name      = node.vm_name
      ip_addresses = node.ip_addresses
    }
  }
}

output "cluster_info" {
  description = "Cluster information"
  value = {
    cluster_name = var.cluster_name
    master_count = length(var.master_nodes)
    worker_count = length(var.worker_nodes)
    total_nodes  = length(var.master_nodes) + length(var.worker_nodes)
  }
}

output "master_ips" {
  description = "List of master node IP addresses"
  value       = [for vm in var.master_nodes : vm.ip_address]
}

output "worker_ips" {
  description = "List of worker node IP addresses"
  value       = [for vm in var.worker_nodes : vm.ip_address]
}