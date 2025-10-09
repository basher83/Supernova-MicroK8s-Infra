# Terraform test to clone template for vm

Template was create on host with:

```bash
qm create 2006 --name template-ubuntu-test --description "Dual NIC, vendor-data" --ostype l26 --machine q35 --cpu host --cores 2 --memory 4096 --balloon 4096 --scsihw virtio-scsi-single --scsi0 local-lvm:0,import-from=/var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img,discard=on,iothread=1,ssd=1 --net0 virtio,bridge=vmbr0 --net1 virtio,bridge=vmbr1 --ipconfig0 ip=dhcp --ipconfig1 ip=dhcp --nameserver "8.8.8.8 1.1.1.1" --rng0 source=/dev/urandom --tablet 0 --boot order=scsi0 --vga serial0 --serial0 socket --ide2 local-lvm:cloudinit --agent 1,fstrim_cloned_disks=1 --bios ovmf --efidisk0 local-lvm:0,efitype=4m,pre-enrolled-keys=0 --cicustom "vendor=local:snippets/vendor-data.yaml" --tags ubuntu --template 1
```

    <!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_infisical"></a> [infisical](#requirement\_infisical) | 0.15.39 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >= 0.84.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_infisical"></a> [infisical](#provider\_infisical) | 0.15.39 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_pve_vm"></a> [pve\_vm](#module\_pve\_vm) | ../../../modules/vm | n/a |

## Resources

| Name | Type |
|------|------|
| [infisical_secrets.proxmox_secrets](https://registry.terraform.io/providers/infisical/infisical/0.15.39/docs/data-sources/secrets) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
