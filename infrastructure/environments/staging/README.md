# Staging Environment

This directory contains the Terraform configuration for the staging environment of the Nomad cluster.

## Infrastructure

- 3 Nomad server nodes
- 3 Nomad client nodes
- Dual network configuration (management + application)

## Deployment

This infrastructure is now managed through Scalr.

Last updated: Migrated to Scalr on 2025-08-02
<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.73.2 |
## Providers

No providers.
## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vm"></a> [vm](#module\_vm) | ../../modules/vm | n/a |
## Resources

No resources.
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ci_ssh_key"></a> [ci\_ssh\_key](#input\_ci\_ssh\_key) | SSH public key injected via cloud-init for VM access | `string` | n/a | yes |
| <a name="input_cloud_init_username"></a> [cloud\_init\_username](#input\_cloud\_init\_username) | Default username provisioned via cloud-init on the VM | `string` | `"ubuntu"` | no |
| <a name="input_proxmox_insecure"></a> [proxmox\_insecure](#input\_proxmox\_insecure) | Set true to skip TLS verification for Proxmox API (not recommended in production) | `bool` | `true` | no |
| <a name="input_pve_api_token"></a> [pve\_api\_token](#input\_pve\_api\_token) | Proxmox API token ID | `string` | n/a | yes |
| <a name="input_pve_api_url"></a> [pve\_api\_url](#input\_pve\_api\_url) | Proxmox API endpoint URL | `string` | n/a | yes |
| <a name="input_vm_bridge_1"></a> [vm\_bridge\_1](#input\_vm\_bridge\_1) | Primary network bridge for NIC0 | `string` | `"vmbr0"` | no |
| <a name="input_vm_bridge_2"></a> [vm\_bridge\_2](#input\_vm\_bridge\_2) | Secondary network bridge for NIC1 (if dual NIC enabled) | `string` | `"vmbr1"` | no |
| <a name="input_vm_datastore"></a> [vm\_datastore](#input\_vm\_datastore) | Target datastore for VM disks (e.g., local-lvm) | `string` | `"local-lvm"` | no |
| <a name="input_vm_disk_size"></a> [vm\_disk\_size](#input\_vm\_disk\_size) | Boot disk size in GiB | `number` | `68` | no |
| <a name="input_vm_tags"></a> [vm\_tags](#input\_vm\_tags) | Default tags for all VMs | `list(string)` | <pre>[<br/>  "terraform",<br/>  "nomad",<br/>  "staging"<br/>]</pre> | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ansible_yaml_inventory"></a> [ansible\_yaml\_inventory](#output\_ansible\_yaml\_inventory) | n/a |
| <a name="output_vm_ids"></a> [vm\_ids](#output\_vm\_ids) | n/a |
| <a name="output_vm_ips"></a> [vm\_ips](#output\_vm\_ips) | n/a |
| <a name="output_vm_names"></a> [vm\_names](#output\_vm\_names) | n/a |
<!-- END_TF_DOCS -->
