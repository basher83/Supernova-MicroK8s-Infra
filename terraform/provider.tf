provider "proxmox" {
  endpoint  = var.pve_api_url
  api_token = var.pve_api_token
  insecure  = var.proxmox_insecure

  # SSH connection required for file upload operations
  ssh {
    agent    = true
    username = var.proxmox_ssh_username
  }
}
