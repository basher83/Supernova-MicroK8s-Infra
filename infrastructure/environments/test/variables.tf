variable "pve_api_url" {
  description = "Proxmox API endpoint for og-homelab"
  type        = string
}

variable "pve_api_token_og" {
  description = "Proxmox API token for og-homelab cluster"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Set true to skip TLS verification for Proxmox API (not recommended outside dev)"
  type        = bool
  default     = false
}

variable "ci_ssh_key_test" {
  description = "SSH public key for test VMs"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp(256|384|521))\\s+\\S+", var.ci_ssh_key_test))
    error_message = "ci_ssh_key_test must be a valid SSH public key (e.g., 'ssh-ed25519 AAAA...')."
  }
}

variable "proxmox_ssh_username" {
  description = "SSH username for Proxmox host connections (required for file uploads)"
  type        = string
  default     = "root"
}

variable "test_vm_configs" {
  description = "Map of test VM configurations"
  type = map(object({
    name     = string
    size     = string # small, medium, large
    os       = string # ubuntu-2204, ubuntu-2404, debian-12
    features = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for cfg in values(var.test_vm_configs) :
      contains(["small", "medium", "large"], cfg.size)
    ])
    error_message = "Each test VM 'size' must be one of: small, medium, large."
  }

  validation {
    condition = alltrue([
      for cfg in values(var.test_vm_configs) :
      contains(["ubuntu-2204", "ubuntu-2404", "debian-12"], cfg.os)
    ])
    error_message = "Each test VM 'os' must be one of: ubuntu-2204, ubuntu-2404, debian-12."
  }

  # Enforce simple DNS-safe names (lowercase, digits, hyphens), max 63 chars
  validation {
    condition = alltrue([
      for cfg in values(var.test_vm_configs) :
      can(regex("^[a-z0-9-]{1,63}$", cfg.name))
    ])
    error_message = "Each test VM 'name' must match ^[a-z0-9-]{1,63}$ (lowercase, digits, hyphens only, max 63 chars)."
  }
}
