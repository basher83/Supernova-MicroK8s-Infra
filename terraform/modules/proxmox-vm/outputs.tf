output "vm_id" {
  description = "The ID of the VM"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  description = "The name of the VM"
  value       = proxmox_virtual_environment_vm.vm.name
}

output "ip_addresses" {
  description = "IP addresses of the VM"
  value = [
    for idx, config in var.ip_configs : {
      interface = idx
      ipv4      = config.ipv4_address
      ipv6      = lookup(config, "ipv6_address", null)
    }
  ]
}

output "node" {
  description = "The Proxmox node the VM is deployed on"
  value       = proxmox_virtual_environment_vm.vm.node_name
}