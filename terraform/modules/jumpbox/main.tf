module "jumpbox_vm" {
  source = "../proxmox-vm"

  vm_id           = var.vm_id
  vm_name         = var.vm_name
  target_node     = var.target_node
  template_id     = var.template_id
  start_on_boot   = true
  qemu_agent      = true

  cpu_cores       = var.cpu_cores
  memory          = var.memory
  machine_type    = "q35"
  bios_type       = "ovmf"
  efi_disk_enabled = true
  vm_description  = "Jumpbox managed by Terraform"
  disk_datastore_id = "local-lvm"
  disk_size       = 20
  disk_iothread   = true
  disk_discard    = "on"

  # Dual-homed network configuration
  network_interfaces = [
    {
      bridge = var.home_network.bridge # Home network access
    },
    {
      bridge = var.cluster_network.bridge # Cluster network access
    }
  ]

  ip_configs = [
    {
      ipv4_address = var.home_network_ip
      ipv4_gateway = var.home_network.gateway
    },
    {
      ipv4_address = "${var.cluster_network_ip}${var.cluster_network.cidr_suffix}"
    }
  ]

  tags = merge(var.common_tags, {
    role = "jumpbox"
    type = "bastion"
  })
}