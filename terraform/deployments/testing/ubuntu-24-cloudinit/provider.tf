# =============================================================================
# = Proxmox Provider Configuration ============================================
# =============================================================================
# IMPORTANT: Template creation requires SSH access to the Proxmox host
# for image import operations. Configure provider as follows:

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure
  # api_token = var.proxmox_api_token
  username = var.proxmox_username
  password = var.proxmox_password
  # Authentication handled via environment variables or API token
  # PROXMOX_VE_USERNAME, PROXMOX_VE_PASSWORD
  # or PROXMOX_VE_API_TOKEN

  # SSH required for image import (cloud image download + import)
  ssh {
    agent       = false            # Use local SSH agent for authentication
    username    = var.ssh_username # SSH user on Proxmox host (e.g., "terraform")
    private_key = var.proxmox_ssh_key
  }
}
