# Preparing Cloud-Init Templates for Proxmox

```text
 qm create ${VM_ID} --name ${VM_NAME} \
    --description \"template created on $(date)\" \
    --ostype ${VM_OS} \
    --bios ${VM_BIOS} --machine ${VM_MACHINE} \
    --scsihw ${VM_SCSIHW} --agent enabled=1 \
    --cores ${VM_CPU_CORES} --sockets ${VM_CPU_SOCKETS} \
    --cpu ${VM_CPU_TYPE} --memory ${VM_MEMORY} \
    --net0 ${VM_NET_TYPE},bridge=${VM_NET_BRIDGE}"
```

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
