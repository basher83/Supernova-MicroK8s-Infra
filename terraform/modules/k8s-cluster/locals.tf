locals {
  all_nodes = concat(
    [for vm in var.master_nodes : {
      name = vm.name
      ip   = vm.ip_address
      role = "master"
    }],
    [for vm in var.worker_nodes : {
      name = vm.name
      ip   = vm.ip_address
      role = "worker"
    }]
  )

  ansible_inventory = {
    masters = [for vm in var.master_nodes : vm.ip_address]
    workers = [for vm in var.worker_nodes : vm.ip_address]
  }
}