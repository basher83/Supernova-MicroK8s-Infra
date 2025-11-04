terraform {
  required_version = "~> 1.9"
}

terraform {
  required_providers {
    infisical = {
      source  = "infisical/infisical"
      version = "0.15.43"
    }
  }
}

provider "infisical" {
  auth = {
    universal = {
      client_id     = "12ae9b10-135c-44b4-a11d-dae56164f188"
      client_secret = "d66f3e44f1c8642d969a9f706e5a855037442d84634413450002b2040e33ef59"
    }
  }
}

data "infisical_secrets" "common_secrets" {
  env_slug     = "dev"
  workspace_id = "7b832220-24c0-45bc-a5f1-ce9794a31259" // project ID
  folder_path  = "/doggos-cluster"
}

output "all-project-secrets-value" {
  value = nonsensitive(data.infisical_secrets.common_secrets.secrets["PROXMOX_ENDPOINT"].value)
}

output "all-project-secrets-comment" {
  value = nonsensitive(data.infisical_secrets.common_secrets.secrets["PROXMOX_ENDPOINT"].comment)
}
