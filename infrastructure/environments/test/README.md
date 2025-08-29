<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | ~> 0.73 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_test_vms"></a> [test\_vms](#module\_test\_vms) | ../../modules/vm | n/a |
## Resources

| Name | Type |
|------|------|
| [random_shuffle.og_nodes](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ci_ssh_key_test"></a> [ci\_ssh\_key\_test](#input\_ci\_ssh\_key\_test) | SSH public key for test VMs | `string` | n/a | yes |
| <a name="input_proxmox_insecure"></a> [proxmox\_insecure](#input\_proxmox\_insecure) | Set true to skip TLS verification for Proxmox API (not recommended outside dev) | `bool` | `false` | no |
| <a name="input_pve_api_token_og"></a> [pve\_api\_token\_og](#input\_pve\_api\_token\_og) | Proxmox API token for og-homelab cluster | `string` | n/a | yes |
| <a name="input_pve_api_url"></a> [pve\_api\_url](#input\_pve\_api\_url) | Proxmox API endpoint for og-homelab | `string` | n/a | yes |
| <a name="input_test_vm_configs"></a> [test\_vm\_configs](#input\_test\_vm\_configs) | Map of test VM configurations | <pre>map(object({<br/>    name     = string<br/>    size     = string # small, medium, large<br/>    os       = string # ubuntu-2204, ubuntu-2404, debian-12<br/>    features = list(string)<br/>  }))</pre> | `{}` | no |
## Outputs

No outputs.
<!-- END_TF_DOCS -->
