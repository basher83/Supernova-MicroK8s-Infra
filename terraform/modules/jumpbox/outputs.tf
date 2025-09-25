output "vm_id" {
  description = "ID of the jumpbox VM"
  value       = module.jumpbox_vm.vm_id
}

output "vm_name" {
  description = "Name of the jumpbox VM"
  value       = module.jumpbox_vm.vm_name
}

output "home_network_ip" {
  description = "Jumpbox IP on home network"
  value       = split("/", var.home_network_ip)[0]
}

output "cluster_network_ip" {
  description = "Jumpbox IP on cluster network"
  value       = var.cluster_network_ip
}

output "ssh_connection" {
  description = "SSH connection string"
  value       = "ssh ansible@${split("/", var.home_network_ip)[0]}"
}

output "ansible_proxy_config" {
  description = "Ansible SSH proxy configuration"
  value = {
    proxy_host = split("/", var.home_network_ip)[0]
    proxy_user = "ansible"
    cluster_ip = var.cluster_network_ip
  }
}