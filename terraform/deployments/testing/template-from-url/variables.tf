
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
  default     = "ubuntu-22-04-template"
}

variable "template_id" {
  type        = number
  description = "VM ID for the template (typically 2000-9999 range)"
  default     = 2006

  validation {
    condition     = var.template_id >= 100 && var.template_id <= 999999999
    error_message = "Template ID must be between 100 and 999999999"
  }
}

# =============================================================================
# = Cloud Image Download Variables ============================================
# =============================================================================

variable "cloud_image_url" {
  type        = string
  description = "URL to download the cloud image from"
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "cloud_image_filename" {
  type        = string
  description = "Filename for the downloaded cloud image"
  default     = "ubuntu-22.04-server-cloudimg-amd64.img"
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
  description = "Proxmox datastore for VM disks"
  default     = "local-lvm"
}

# =============================================================================
# = Network Variables =========================================================
# =============================================================================

variable "network_bridge" {
  type        = string
  description = "Network bridge for the template"
  default     = "vmbr0"
}
