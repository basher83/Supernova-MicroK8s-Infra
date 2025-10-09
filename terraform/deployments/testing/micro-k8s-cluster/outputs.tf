# =============================================================================
# = Cluster Outputs ===========================================================
# =============================================================================

output "cluster_ips" {
  description = "Map of node names to IP addresses"
  value       = module.microk8s_cluster.cluster_ips
}

output "cluster_ids" {
  description = "Map of node names to VM IDs"
  value       = module.microk8s_cluster.cluster_ids
}

output "cluster_inventory" {
  description = "Ansible-friendly inventory"
  value       = module.microk8s_cluster.cluster_inventory
}

output "cluster_summary" {
  description = "Human-readable cluster summary"
  value       = module.microk8s_cluster.cluster_summary
}

output "ssh_commands" {
  description = "SSH commands to connect to each node"
  value = {
    for name, ip in module.microk8s_cluster.cluster_ips :
    name => "ssh ansible@${ip}"
  }
}
