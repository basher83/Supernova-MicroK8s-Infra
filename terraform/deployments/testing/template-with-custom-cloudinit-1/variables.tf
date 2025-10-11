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
  default     = "ubuntu-24-04-custom-cloudinit-template"
}

variable "template_id" {
  type        = number
  description = "VM ID for the template (typically 2000-9999 range)"
  default     = 2008

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
  default     = "user-data.yaml"
}

variable "user_data_snippet_name" {
  type        = string
  description = "Name for the user-data snippet file in Proxmox storage"
  default     = "user-data-custom.yaml"
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

variable "vm_bios" {
  type        = string
  description = "BIOS implementation"
  default     = "ovmf"
}

variable "vm_machine" {
  type        = string
  description = "Machine type"
  default     = "q35"
}

variable "vm_os" {
  type        = string
  description = "Operating system type"
  default     = "l26"
}

variable "cpu_cores" {
  type        = number
  description = "Number of CPU cores"
  default     = 2
}

variable "cpu_type" {
  type        = string
  description = "CPU type"
  default     = "host"
}

variable "memory" {
  type        = number
  description = "Memory in MB"
  default     = 2048
}

variable "disk_size" {
  type        = number
  description = "Disk size in GB (keep minimal for templates, expand during clone)"
  default     = 12
}

variable "qemu_agent_enabled" {
  type        = bool
  description = "Enable QEMU guest agent"
  default     = true
}

variable "qemu_agent_timeout" {
  type        = string
  description = "QEMU agent timeout"
  default     = "15m"
}

variable "qemu_agent_trim" {
  type        = bool
  description = "Enable fstrim for cloned disks"
  default     = true
}

variable "disk_file_format" {
  type        = string
  description = "Disk file format"
  default     = "raw"
}

variable "disk_iothread" {
  type        = bool
  description = "Enable IO thread"
  default     = true
}

variable "disk_ssd" {
  type        = bool
  description = "Enable SSD emulation"
  default     = true
}

variable "disk_discard" {
  type        = string
  description = "Disk discard option"
  default     = "on"
}

variable "efi_disk_format" {
  type        = string
  description = "EFI disk file format"
  default     = "raw"
}

variable "efi_disk_type" {
  type        = string
  description = "EFI disk type"
  default     = "4m"
}

# =============================================================================
# = Network Variables =========================================================
# =============================================================================

variable "network_bridge" {
  type        = string
  description = "Network bridge for the template"
  default     = "vmbr0"
}

variable "network_firewall" {
  type        = bool
  description = "Enable firewall for network interface"
  default     = false
}

# =============================================================================
# = Cloud-init Interface Configuration ========================================
# =============================================================================

variable "cloud_init_interface" {
  type        = string
  description = "Interface for cloud-init drive"
  default     = "ide2"
}
