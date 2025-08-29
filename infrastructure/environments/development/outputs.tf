# --- Outputs for development environment ---

output "vm_names" {
  value = [for vm in module.vm : vm.vm_name]
}

output "vm_ips" {
  value = [for vm in module.vm : vm.primary_ip]
}

output "vm_ids" {
  value = [for vm in module.vm : vm.vm_id]
}

output "ansible_yaml_inventory" {
  value = yamlencode({
    all = {
      hosts = {
        for name, vm in module.vm :
        name => {
          ansible_host = vm.primary_ip
        }
      }
    }
  })
}
