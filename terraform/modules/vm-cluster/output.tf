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

output "cluster_nodes" {
  description = "Map of all cluster nodes with their details"
  value = {
    for name, vm in module.cluster_vms : name => {
      vm_id          = vm.vm_id
      vm_name        = vm.vm_name
      node           = vm.vm_node
      ipv4_addresses = vm.ipv4_addresses
      ipv6_addresses = vm.ipv6_addresses
      mac_addresses  = vm.mac_addresses
    }
  }
}

output "cluster_ips" {
  description = "Map of node names to their primary IPv4 addresses"
  value = {
    for name, vm in module.cluster_vms :
    name => try(vm.ipv4_addresses[1][0], vm.ipv4_addresses[0][0], "N/A")
  }
}

output "cluster_ids" {
  description = "Map of node names to their VM IDs"
  value = {
    for name, vm in module.cluster_vms :
    name => vm.vm_id
  }
}

output "cluster_macs" {
  description = "Map of node names to their MAC addresses"
  value = {
    for name, vm in module.cluster_vms :
    name => vm.mac_addresses
  }
}

output "cluster_inventory" {
  description = "Ansible-friendly inventory output with hostnames and IPs"
  value = {
    all = {
      hosts = {
        for name, vm in module.cluster_vms :
        name => {
          ansible_host = try(vm.ipv4_addresses[1][0], vm.ipv4_addresses[0][0], "N/A")
          vm_id        = vm.vm_id
          pve_node     = vm.vm_node
        }
      }
    }
  }
}

output "cluster_summary" {
  description = "Human-readable cluster summary"
  value       = <<-EOT
    Cluster Deployment Summary
    ==========================
    Total Nodes: ${length(module.cluster_vms)}

    Nodes:
    ${join("\n    ", [for name, vm in module.cluster_vms : "${name}: ${try(vm.ipv4_addresses[1][0], vm.ipv4_addresses[0][0], "N/A")} (ID: ${vm.vm_id}, Node: ${vm.vm_node})"])}
  EOT
}
