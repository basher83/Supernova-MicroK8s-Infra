# Minimum configuration required for successful clone of a Proxmox template.

module "pve_vm" {
  source = "../../../modules/vm"

  vm_type  = "clone"
  pve_node = nonsensitive(data.infisical_secrets.proxmox_secrets.secrets["PROXMOX_CLONE_NODE"].value)

  src_clone = {
    datastore_id = "local-lvm"
    tpl_id       = 2006
  }

  vm_name = "example-basic"


  vm_efi_disk = {
    datastore_id = "local-lvm"
  }

  vm_disk = {
    scsi0 = {
      datastore_id = "local-lvm"
      size         = 8
      main_disk    = true
    }
  }

  vm_net_ifaces = {
    net0 = {
      bridge    = "vmbr0"
      ipv4_addr = "192.168.10.111/24"
      ipv4_gw   = "192.168.10.1"
      #tag = ""
    }
    #    net1 = {
    #      bridge    = "vmbr1"
    #      ipv4_addr = "dhcp"
    #      #ipv4_gw   = "192.168.10.1"
    #      tag = "2"
    #    }
  }

  vm_init = {
    datastore_id = "local"
    interface    = "ide0"
  }
}
