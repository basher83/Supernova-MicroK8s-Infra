provider "proxmox" {
  endpoint  = var.pve_api_url
  api_token = var.pve_api_token_og
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    username = var.proxmox_ssh_username
  }
}
