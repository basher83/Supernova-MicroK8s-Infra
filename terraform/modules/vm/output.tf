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
