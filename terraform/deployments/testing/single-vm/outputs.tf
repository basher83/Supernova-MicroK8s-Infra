# =============================================================================
# = VM Outputs ================================================================
# =============================================================================

output "vm_id" {
  description = "The VM ID in Proxmox"
  value       = module.single_vm.vm_id
}

output "vm_name" {
  description = "The VM name"
  value       = module.single_vm.vm_name
}

output "vm_node" {
  description = "The Proxmox node where the VM is deployed"
  value       = module.single_vm.vm_node
}

output "ip_address" {
  description = "Primary IPv4 address of the VM"
  value       = try(module.single_vm.ipv4_addresses[1][0], module.single_vm.ipv4_addresses[0][0], "N/A")
}

output "all_ip_addresses" {
  description = "All IPv4 addresses assigned to the VM"
  value       = module.single_vm.ipv4_addresses
}

output "mac_address" {
  description = "MAC address of the VM's primary network interface"
  value       = try(module.single_vm.mac_addresses[0], "N/A")
}

output "all_mac_addresses" {
  description = "All MAC addresses assigned to the VM"
  value       = module.single_vm.mac_addresses
}
