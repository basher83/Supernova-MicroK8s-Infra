# Grant Terraform Access to Proxmox

In order for Terraform to be able to create templates in Proxmox, it will need to have SSH access to the PVE server. Unlike prior post, we’ll create a new linux user, terraform, on the PVE host server and add that user within the Proxmox UI under the PAM realm.

If you already created a user under the PVE realm, `terraform@pve`, I suggest removing that user and permissions to avoid confusion:

## delete user and token

```bash
pveum user delete terraform@pve
```

For additional information, see pveum help user or Proxmox Docs: User Authentication.

## Create User on PVE Server

First, start by logging into the PVE server as a privileged user. Then create a new linux user and password:

### SSH into the PVE server

```bash
ssh root@<PVE_SERVER_ADDRESS>
```

### create user 'terraform'

```bash
adduser --home /home/terraform --shell /bin/bash terraform
```

### add user to sudoers

```bash
usermod -aG sudo terraform
```

Next, give the terraform user permission to use PVE commands without a password. We’ll use the commands from the provider documentation on ‘SSH User’:

### create a sudoers file for terraform user

```bash
visudo -f /etc/sudoers.d/terraform
```

Add the following line at the end of the file and save it:

```bash
terraform ALL=(root) NOPASSWD: /sbin/pvesm
terraform ALL=(root) NOPASSWD: /sbin/qm
terraform ALL=(root) NOPASSWD: /usr/bin/tee /var/lib/vz/\*
```

## SSH Access

Now let’s create a dedicated SSH key and add it to the `/home/terraform/.ssh/authorized_keys` file on the PVE server. Start by creating a new key on your local desktop using ssh-keygen:

### create a new ssh key pair

```bash
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/terraform_id_ed25519 -C "USER_EMAIL"
```

### example output

```bash
user@desktop:~$ ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/terraform_id_ed25519 -C "USER_EMAIL"
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/user/.ssh/terraform_id_ed25519
Your public key has been saved in /home/user/.ssh/terraform_id_ed25519.pub
The key fingerprint is:
SHA256:uimKIsvhgDs8J5B155+e4S1HSKl9XewoqsgE1SEVLNA USER_EMAIL
The key's randomart image is:
+--[ED25519 256]--+
| .o.o+. |
| Eo.. |
| ... . . |
| ... . o o |
| o.. o +S. . + |
|+ . o.o + o . |
|=. . ...= . |
|B*.+.. +=+. |
|*==.o.+o+o. |
+----[SHA256]-----+
```

### view the public key

```bash
user@desktop:~$ cat ~/.ssh/terraform_id_ed25519.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQYTV18SN+39z9W99SzaJoc8VncoLyjhLulVH+pkkZ2 USER_EMAIL
```

Now, add the key to the terraform user’s authorized keys file on the Proxmox server. You can do this by running ssh-copy-id from your local desktop:

```bash
ssh-copy-id -i ~/.ssh/terraform_id_ed25519.pub terraform@<PVE_SERVER_ADDRESS>
```

Alternatively, you can manually append the public key value into /home/terraform/.ssh/authorized_keys:

### Get the public key from your local machine

```bash
user@desktop:~$ cat ~/.ssh/terraform_id_ed25519.pub
```

### SSH into Proxmox

```bash
user@desktop:~$ ssh root@<PVE_SERVER_ADDRESS>
```

### Use your favorite editor to edit the file

```bash
root@pve:~# vim /home/terraform/.ssh/authorized_keys
```

### Paste the public key value into the file and save it

Confirm the key was added by SSHing into the server:

```bash
ssh -i ~/.ssh/terraform_id_ed25519 terraform@<PVE_SERVER_ADDRESS>
```

## API Access

Next, let’s create a Terraform user, group and token to access the Proxmox API. You’ll need to permit access to the root path, /, of the Proxmox server, as the BPG file download resource will need to gather file metadata information. On your Proxmox server, run the following as a privileged user:

### create role in PVE 8

```bash
pveum role add TerraformUser -privs "Datastore.Allocate \
 Datastore.AllocateSpace Datastore.AllocateTemplate \
 Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify \
 SDN.Use VM.Allocate VM.Audit VM.Clone VM.Config.CDROM \
 VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType \
 VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate \
 VM.Monitor VM.PowerMgmt User.Modify"
```

### create group

```bash
pveum group add terraform-users
```

### add permissions

```bash
pveum acl modify / -group terraform-users -role TerraformUser
```

### create user 'terraform'

```bash
pveum useradd terraform@pam -groups terraform-users
```

### generate a token

```bash
pveum user token add terraform@pam token -privsep 0
```

The last command will output a token value similar to the following:

```bash
┌──────────────┬──────────────────────────────────────┐
│ key │ value │
╞══════════════╪══════════════════════════════════════╡
│ full-tokenid │ terraform@pam!token │
├──────────────┼──────────────────────────────────────┤
│ info │ {"privsep":"0"} │
├──────────────┼──────────────────────────────────────┤
│ value │ 782a7700-4010-4802-8f4d-820f1b226850 │
└──────────────┴──────────────────────────────────────┘
```
