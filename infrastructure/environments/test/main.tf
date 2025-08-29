locals {
  # templates on og-homelab (proxmoxt430/pve)
  vm_templates = {
    ubuntu-2204 = { template_id = 8000, username = "ubuntu" }
    ubuntu-2404 = { template_id = 8001, username = "ubuntu" }
    debian-12   = { template_id = 8002, username = "debian" }
  }

  sizes = {
    # NOTE: memory values defined but not used - VM module currently lacks memory parameter
    # VMs will inherit memory from template until module is updated
    small  = { vcpu = 2, memory = 2048, disk = 20 }
    medium = { vcpu = 4, memory = 4096, disk = 40 }
    large  = { vcpu = 8, memory = 8192, disk = 80 }
  }
}

resource "random_shuffle" "og_nodes" {
  input        = ["proxmoxt430", "pve"]
  result_count = 1
}

module "test_vms" {
  for_each = var.test_vm_configs

  source = "../../modules/vm"

  vm_name = each.value.name
  # Stable, deterministic ID based on key hash, avoids churn when map entries change
  vm_id        = 5000 + (parseint(substr(sha1(each.key), 0, 4), 16) % 900) + 1
  vm_node_name = random_shuffle.og_nodes.result[0]
  # Sizing
  vcpu         = local.sizes[each.value.size].vcpu
  vcpu_type    = "host"
  vm_datastore = "local-lvm"
  vm_disk_size = local.sizes[each.value.size].disk
  # TODO: Add memory parameter once VM module supports it
  # memory = local.sizes[each.value.size].memory

  # Networking - using test subnet
  vm_bridge_1         = "vmbr0"
  vm_bridge_2         = ""
  vm_ip_primary       = "10.0.50.${100 + index(keys(var.test_vm_configs), each.key) + 1}/24"
  vm_gateway          = "10.0.50.1"
  enable_dual_network = false

  # Cloud-init
  cloud_init_username = local.vm_templates[each.value.os].username
  ci_ssh_key          = var.ci_ssh_key_test

  # Template ID for cloning
  template_id = local.vm_templates[each.value.os].template_id

  vm_tags = ["terraform", "test", "temporary", "og-homelab"]
}
