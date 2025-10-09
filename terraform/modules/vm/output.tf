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
# ===== Outputs ===============================================================
# =============================================================================

output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_virtual_environment_vm.pve_vm.id
}

output "vm_name" {
  description = "The name of the created VM"
  value       = proxmox_virtual_environment_vm.pve_vm.name
}

output "vm_node" {
  description = "The Proxmox node where the VM is deployed"
  value       = proxmox_virtual_environment_vm.pve_vm.node_name
}

output "ipv4_addresses" {
  description = "List of IPv4 addresses assigned to the VM"
  value       = proxmox_virtual_environment_vm.pve_vm.ipv4_addresses
}

output "ipv6_addresses" {
  description = "List of IPv6 addresses assigned to the VM"
  value       = proxmox_virtual_environment_vm.pve_vm.ipv6_addresses
}

output "mac_addresses" {
  description = "List of MAC addresses assigned to the VM network interfaces"
  value       = proxmox_virtual_environment_vm.pve_vm.mac_addresses
}

output "vm_resource" {
  description = "Full VM resource object for advanced use cases"
  value       = proxmox_virtual_environment_vm.pve_vm
  sensitive   = true
}
