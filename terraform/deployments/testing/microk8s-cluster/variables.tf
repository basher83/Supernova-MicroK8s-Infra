# Copyright 2025 RalZareck
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# =============================================================================
# = Proxmox Configuration =====================================================
# =============================================================================

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = "https://proxmox.local:8006"
}

variable "proxmox_insecure" {
  description = "Allow insecure TLS connections to Proxmox"
  type        = bool
  default     = true
}

# =============================================================================
# = Template Configuration ====================================================
# =============================================================================

variable "template_id" {
  description = "VM template ID to clone from"
  type        = number
  default     = 2000
}

variable "template_node" {
  description = "Proxmox node where the template is located (for cross-node cloning)"
  type        = string
  default     = "lloyd"
}

variable "datastore" {
  description = "Datastore for VM disks"
  type        = string
  default     = "local-lvm"
}

# =============================================================================
# = Network Configuration =====================================================
# =============================================================================

variable "network_bridge" {
  description = "Network bridge for VMs"
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "VLAN ID for network isolation (null for no VLAN)"
  type        = number
  default     = null
}

variable "network_cidr" {
  description = "Network CIDR suffix (e.g., '24' for /24)"
  type        = string
  default     = "24"
}

variable "network_gateway" {
  description = "Network gateway IP address"
  type        = string
  default     = "192.168.30.1"
}

# =============================================================================
# = Secondary Network Configuration (Optional) ================================
# =============================================================================

variable "enable_secondary_nic" {
  description = "Enable secondary network interface for all cluster nodes"
  type        = bool
  default     = true
}

variable "network_bridge_secondary" {
  description = "Secondary network bridge for VMs"
  type        = string
  default     = "vmbr1"
}

variable "vlan_id_secondary" {
  description = "VLAN ID for secondary network interface (null for no VLAN)"
  type        = number
  default     = null
}
