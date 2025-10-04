data "proxmox_virtual_environment_file" "vendor_data" {
  node_name    = var.template_node
  datastore_id = "local"
  content_type = "snippets"
  file_name    = "vendor-data.yaml"
}
