# Preparing Cloud-Init Templates for Proxmox

## Working example

For the jumphost template:

```bash
qm create 2000 \
  --name jumpbox-ansible-k8s \
  --description "Jumpbox ansible k8s template" \
  --ostype l26 \
  --machine q35 \
  --cpu host \
  --cores 2 \
  --memory 4096 \
  --balloon 4096 \
  --scsihw virtio-scsi-single \
  --scsi0 local-lvm:0,import-from=/var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img,discard=on,iothread=1,ssd=1 \
  --net0 virtio,bridge=vmbr0 \
  --net1 virtio,bridge=vmbr1,tag=2 \
  --ipconfig0 ip=192.168.10.240/24,gw=192.168.10.1 \
  --ipconfig1 ip=192.168.4.240/24 \
  --nameserver "8.8.8.8 1.1.1.1" \
  --rng0 source=/dev/urandom \
  --tablet 0 \
  --boot order=scsi0 \
  --vga serial0 \
  --serial0 socket \
  --ide2 local-lvm:cloudinit \
  --agent 1,fstrim_cloned_disks=1 \
  --bios ovmf \
  --efidisk0 local-lvm:0,efitype=4m,pre-enrolled-keys=0 \
  --cicustom "user=local:snippets/jumpbox.yaml" \
  --tags ubuntu,jumpbox \
  --template 1
```

```bash
qm clone 2000 399 --full --name "jumpbox-ansible-k8s"
qm resize 399 scsi0 10G
qm migrate 399 holly --with-local-disks 1
qm start 399
```

For the microk8s-cluster template:

```bash
qm create 2001 \
  --name microk8s-cluster \
  --description "MicroK8s cluster template" \
  --ostype l26 \
  --machine q35 \
  --cpu host \
  --cores 2 \
  --memory 8192 \
  --balloon 8192 \
  --scsihw virtio-scsi-single \
  --scsi0 local-lvm:0,import-from=/var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img,discard=on,iothread=1,ssd=1 \
  --net1 virtio,bridge=vmbr1,tag=2 \
  --ipconfig1 ip=dhcp \
  --nameserver "8.8.8.8 1.1.1.1" \
  --rng0 source=/dev/urandom \
  --tablet 0 \
  --boot order=scsi0 \
  --vga serial0 \
  --serial0 socket \
  --ide2 local-lvm:cloudinit \
  --agent 1,fstrim_cloned_disks=1 \
  --bios ovmf \
  --efidisk0 local-lvm:0,efitype=4m,pre-enrolled-keys=0 \
  --cicustom "user=local:snippets/microk8s.yaml" \
  --tags ubuntu,microk8s \
  --template 1
```

## Clone the template and set the IP addresses

```bash
qm clone 2001 311 --full --name "microk8s-1"
qm set 311 --ipconfig1 ip=192.168.4.11/24,gw=192.168.4.1
qm resize 311 scsi0 50G
qm start 311

qm clone 2001 312 --full --name "microk8s-2"
qm set 312 --ipconfig1 ip=192.168.4.12/24,gw=192.168.4.1
qm resize 312 scsi0 50G
qm migrate 312 mable --with-local-disks 1
qm start 312

qm clone 2001 313 --full --name "microk8s-3"
qm set 313 --ipconfig1 ip=192.168.4.13/24,gw=192.168.4.1
qm resize 313 scsi0 50G
qm migrate 313 holly --with-local-disks 1
qm start 313
```

```bash
qm create 2007 --name template-microk8s-test --description "Dual NIC, vendor-data" --ostype l26 --machine q35 --cpu host --cores 2 --memory 4096 --balloon 4096 --scsihw virtio-scsi-single --scsi0 local-lvm:0,import-from=/var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img,discard=on,iothread=1,ssd=1 --net0 virtio,bridge=vmbr0 --net1 virtio,bridge=vmbr1 --ipconfig0 ip=dhcp --ipconfig1 ip=dhcp --nameserver "8.8.8.8 1.1.1.1" --rng0 source=/dev/urandom --tablet 0 --boot order=scsi0 --vga serial0 --serial0 socket --ide2 local-lvm:cloudinit --agent 1,fstrim_cloned_disks=1 --bios ovmf --efidisk0 local-lvm:0,efitype=4m,pre-enrolled-keys=0 --cicustom "user=local:snippets/vendor-data.yaml" --tags ubuntu,microk8s,test --template 1
```

### Explanation:

--bios ovmf --machine q35:
This enables UEFI boot (OVMF) using the modern q35 chipset. Required for UEFI/cloud-image compatibility.

--efidisk0 local-lvm:0,efitype=4m,pre-enrolled-keys=0:
This creates the EFI vars disk with UEFI support but no Secure Boot enabled by default, which is recommended for general Linux templates—especially for cloud-init/automation scenarios.

--ostype l26:
Correct for modern Linux distributions (including Ubuntu).

--agent 1:
Enables qemu-guest-agent, best practice for cloud-init VMs.

--vga serial0 --serial0 socket:
Preferred for headless/server templates and serial access.

--net0 virtio,bridge=vmbr0:
Virtio NIC with your main bridge, optimal for performance.

CPU/memory/cores/sockets:
Appropriate base template values—scale as needed for your environment.

Already many distributions provide ready-to-use Cloud-Init images (provided as .qcow2 files), so alternatively you can simply download and import such images. For the following example, we will use the cloud image provided by Ubuntu at https://cloud-images.ubuntu.com.

## download the image

```text
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
```

**Ubuntu Cloud-Init images require the virtio-scsi-pci controller type for SCSI drives.**

## create a new VM with VirtIO SCSI controller

```text
qm create 9000 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci
```

## import the downloaded disk to the local-lvm storage, attaching it as a SCSI drive

```text
qm set 9000 --scsi0 local-lvm:0,import-from=/path/to/bionic-server-cloudimg-amd64.img
```

## Add Cloud-Init CD-ROM drive

The next step is to configure a CD-ROM drive, which will be used to pass the Cloud-Init data to the VM.

```text
qm set 9000 --ide2 local-lvm:cloudinit
```

To be able to boot directly from the Cloud-Init image, set the boot parameter to `order=scsi0` to restrict BIOS to boot from this disk only. This will speed up booting, because VM BIOS skips the testing for a bootable CD-ROM.

```text
qm set 9000 --boot order=scsi0
```

For many Cloud-Init images, it is required to configure a serial console and use it as a display. If the configuration doesn’t work for a given image however, switch back to the default display instead.

```text
qm set 9000 --serial0 socket --vga serial0
```

In a last step, it is helpful to convert the VM into a template. From this template you can then quickly create linked clones. The deployment from VM templates is much faster than creating a full clone (copy).

```text
qm template 9000
```

## Deploying Cloud-Init Templates

You can easily deploy such a template by cloning:

```text
qm clone 9000 123 --name ubuntu2
```

Then configure the SSH public key used for authentication, and configure the IP setup:

```text
qm set 123 --sshkey ~/.ssh/id_rsa.pub
```

```text
qm set 123 --ipconfig0 ip=10.0.10.123/24,gw=10.0.10.1
```

You can also configure all the Cloud-Init options using a single command only. We have simply split the above example to separate the commands for reducing the line length. Also make sure to adopt the IP setup for your specific environment.

## Cloud-Init integration

The Cloud-Init integration also allows custom config files to be used instead of the automatically generated configs. This is done via the cicustom option on the command line:

```text
qm set 9000 --cicustom "user=<volume>,network=<volume>,meta=<volume>"
```

The custom config files have to be on a storage that supports snippets and have to be available on all nodes the VM is going to be migrated to. Otherwise the VM won't be able to start. For example:

```text
qm set 9000 --cicustom "user=local:snippets/userconfig.yaml"
```

There are three kinds of configs for Cloud-Init. The first one is the user config as seen in the example above. The second is the network config and the third the meta config. They can all be specified together or mixed and matched however needed. The automatically generated config will be used for any that don't have a custom config file specified.

The generated config can be dumped to serve as a base for custom configs:

```text
qm cloudinit dump 9000 user
```

The same command exists for `network` and `meta`.

## Cloud-Init specific Options

cicustom: [meta=<volume>] [,network=<volume>] [,user=<volume>] [,vendor=<volume>]
Specify custom files to replace the automatically generated ones at start.

meta=<volume>
Specify a custom file containing all meta data passed to the VM via" ." cloud-init. This is provider specific meaning configdrive2 and nocloud differ.

network=<volume>
To pass a custom file containing all network data to the VM via cloud-init.

user=<volume>
To pass a custom file containing all user data to the VM via cloud-init.

vendor=<volume>
To pass a custom file containing all vendor data to the VM via cloud-init.

cipassword: <string>
Password to assign the user. Using this is generally not recommended. Use ssh keys instead. Also note that older cloud-init versions do not support hashed passwords.

citype: <configdrive2 | nocloud | opennebula>
Specifies the cloud-init configuration format. The default depends on the configured operating system type (ostype. We use the nocloud format for Linux, and configdrive2 for windows.

ciupgrade: <boolean> (default = 1)
do an automatic package upgrade after the first boot.

ciuser: <string>
User name to change ssh keys and password for instead of the image’s configured default user.

ipconfig[n]: [gw=<GatewayIPv4>] [,gw6=<GatewayIPv6>] [,ip=<IPv4Format/CIDR>] [,ip6=<IPv6Format/CIDR>]
Specify IP addresses and gateways for the corresponding interface.

IP addresses use CIDR notation, gateways are optional but need an IP of the same type specified.

The special string dhcp can be used for IP addresses to use DHCP, in which case no explicit gateway should be provided. For IPv6 the special string auto can be used to use stateless autoconfiguration. This requires cloud-init 19.4 or newer.

If cloud-init is enabled and neither an IPv4 nor an IPv6 address is specified, it defaults to using dhcp on IPv4.

gw=<GatewayIPv4>
Default gateway for IPv4 traffic.

Note Requires option(s): ip
gw6=<GatewayIPv6>
Default gateway for IPv6 traffic.

Note Requires option(s): ip6
ip=<IPv4Format/CIDR> (default = dhcp)
IPv4 address in CIDR format.

ip6=<IPv6Format/CIDR> (default = dhcp)
IPv6 address in CIDR format.

nameserver: <string>
Sets DNS server IP address for a container. Create will automatically use the setting from the host if neither searchdomain nor nameserver are set.

searchdomain: <string>
Sets DNS search domains for a container. Create will automatically use the setting from the host if neither searchdomain nor nameserver are set.

sshkeys: <string>
Setup public SSH keys (one key per line, OpenSSH format).

## Resouces

[bastientraverse.com](https://bastientraverse.com/en/proxmox-optimized-cloud-init-templates/)
[cloudinit.readthedocs.io](https://cloudinit.readthedocs.io/en/latest/index.html)
[trfore.com](https://www.trfore.com/posts/golden-images-and-proxmox-templates-using-cloud-init/)
