# =============================================================================
# = Provider Variables =======================================================
# =============================================================================

variable "ssh_username" {
  type        = string
  description = "SSH username for Proxmox host (required for image import)"
  default     = "terraform"
}

variable "proxmox_ssh_key" {
  type        = string
  description = "SSH key for Proxmox host (required for image import)"
  default     = null
  sensitive   = true
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox username for authentication"
  sensitive   = true
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox password for authentication"
  sensitive   = true
}

# =============================================================================
# = Proxmox Connection Variables ==============================================
# =============================================================================

variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint (e.g., https://proxmox.example.com:8006)"
}

variable "proxmox_insecure" {
  type        = bool
  description = "Skip TLS verification (useful for self-signed certificates)"
  default     = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name where the template will be created"
}

# =============================================================================
# = Template Configuration Variables ==========================================
# =============================================================================

variable "template_name" {
  type        = string
  description = "Name for the VM template"
  default     = "ubuntu24-cloudinit-template"
}

variable "template_id" {
  type        = number
  description = "VM ID for the template (typically 2000-9999 range)"
  default     = 9001

  validation {
    condition     = var.template_id >= 100 && var.template_id <= 999999999
    error_message = "Template ID must be between 100 and 999999999"
  }
}

# =============================================================================
# = Cloud-Init Configuration Variables ========================================
# =============================================================================

variable "user_data_file" {
  type        = string
  description = "Path to the cloud-init user-data YAML file to upload"
  default     = "../shared/user-data.yaml"
}

variable "user_data_snippet_name" {
  type        = string
  description = "Name for the user-data snippet file in Proxmox storage"
  default     = "ubuntu24-cloudinit.yaml"
}

variable "cloud_init_datastore" {
  type        = string
  description = "Proxmox datastore for cloud-init snippets (must support snippets, typically 'local')"
  default     = "local"
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for cloud-init network configuration"
  default     = ["1.1.1.1", "8.8.8.8"]
}

# =============================================================================
# = Cloud Image Download Variables ============================================
# =============================================================================

variable "cloud_image_url" {
  type        = string
  description = "URL to download the cloud image from"
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "cloud_image_filename" {
  type        = string
  description = "Filename for the downloaded cloud image"
  default     = "noble-server-cloudimg-amd64.img"
}

variable "cloud_image_checksum" {
  type        = string
  description = "Checksum of the cloud image for integrity verification (optional but recommended for production). Uses SHA256 by default."
  default     = null
}

variable "cloud_image_datastore" {
  type        = string
  description = "Proxmox datastore for cloud image downloads (must be file-based storage like 'local', NOT block-based like 'local-lvm')"
  default     = "local"
}

# =============================================================================
# = Storage Variables =========================================================
# =============================================================================

variable "datastore" {
  type        = string
  description = "Proxmox datastore for VM disks (can be block-based storage like 'local-lvm')"
  default     = "local-lvm"
}

# =============================================================================
# = Template Metadata =========================================================
# =============================================================================

variable "template_description" {
  type        = string
  description = "Description for the VM template"
  default     = "Ubuntu 24.04 LTS Cloud Template with Custom Cloud-Init"
}

variable "template_tags" {
  type        = list(string)
  description = "Tags to apply to the template"
  default     = ["template", "ubuntu", "cloud-init", "custom"]
}

# =============================================================================
# = Hardware Configuration ====================================================
# =============================================================================

variable "disk_size" {
  type        = number
  description = "Disk size in GB (keep minimal for templates, expand during clone)"
  default     = 5
}

# Note: CPU, memory, BIOS, machine, OS, agent, disk format settings removed
# Templates use module defaults - customize during cloning
# See terraform/modules/vm/DEFAULTS.md for default values

# =============================================================================
# = Network Variables =========================================================
# =============================================================================

variable "network_bridge" {
  type        = string
  description = "Network bridge for the template"
  default     = "vmbr0"
}

# Note: network_firewall removed - module defaults to false
# Note: cloud_init_interface removed - module defaults to "ide2"
