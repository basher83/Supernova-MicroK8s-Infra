provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = "root@pam"
  password = var.pm_password
  insecure = true

  ssh {
    agent = true
  }
}
