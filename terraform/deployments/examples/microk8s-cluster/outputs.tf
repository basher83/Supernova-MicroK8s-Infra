# Copyright 2025 RalZareck
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    name => "ssh ubuntu@${ip}"
  }
}
