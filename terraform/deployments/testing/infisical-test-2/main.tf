terraform {
  required_version = "~> 1.9"
}

terraform {
  required_providers {
    infisical = {
      source  = "infisical/infisical"
      version = "0.15.57"
    }
  }
}

provider "infisical" {
  #  Set INFISICAL_UNIVERSAL_AUTH_CLIENT_ID and
  #  INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET in .mise.local.toml
}

data "infisical_secrets" "common_secrets" {
  env_slug     = "dev"
  workspace_id = "7b832220-24c0-45bc-a5f1-ce9794a31259"
  folder_path  = "/doggos-cluster"
}

output "all-project-secrets-value" {
  value = nonsensitive(data.infisical_secrets.common_secrets.secrets["PROXMOX_ENDPOINT"].value)
}

output "all-project-secrets-comment" {
  value = nonsensitive(data.infisical_secrets.common_secrets.secrets["PROXMOX_ENDPOINT"].comment)
}
