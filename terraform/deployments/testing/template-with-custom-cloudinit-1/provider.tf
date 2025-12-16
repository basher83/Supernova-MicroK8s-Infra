
terraform {
  required_version = "~> 1.9"
}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.84.1"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "0.15.55"
    }
  }
}

provider "infisical" {
  #  Set INFISICAL_UNIVERSAL_AUTH_CLIENT_ID and
  #  INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET in .mise.local.toml
}

data "infisical_secrets" "proxmox_secrets" {
  env_slug     = "dev"
  workspace_id = "7b832220-24c0-45bc-a5f1-ce9794a31259"
  folder_path  = "/nexus_cluster"
}

provider "proxmox" {
  username = sensitive(data.infisical_secrets.proxmox_secrets.secrets["PROXMOX_USERNAME"].value)
  password = sensitive(data.infisical_secrets.proxmox_secrets.secrets["PROXMOX_PASSWORD"].value)
  # api_token = sensitive(data.infisical_secrets.proxmox_secrets.secrets["PROXMOX_TERRAFORM_API_TOKEN_NEXUS"].value)
  endpoint = sensitive(data.infisical_secrets.proxmox_secrets.secrets["PROXMOX_ENDPOINT"].value)
  insecure = true
  ssh {
    agent    = true
    username = var.ssh_username
  }
}

variable "ssh_username" {
  type        = string
  description = "Username for the SSH connection to the Proxmox node"
  default     = "terraform"
}
