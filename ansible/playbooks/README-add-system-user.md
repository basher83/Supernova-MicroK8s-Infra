# Add System User Playbook

## Overview
This playbook creates a system user with:
- Home directory
- SSH key authentication
- Sudo privileges for specific commands (Proxmox management)

## Default Configuration

### User Settings
- **Username**: `terraform`
- **Shell**: `/bin/bash`
- **Comment**: "Terraform automation user"

### SSH Keys
The playbook copies the `files/terraform_authorized_keys` file to `~/.ssh/authorized_keys` on each target host.

To add or remove SSH keys, edit the `files/terraform_authorized_keys` file:
```bash
cd ansible/files
vi terraform_authorized_keys
```

Each line should contain one SSH public key in standard OpenSSH format.

### Sudo Privileges
The user gets NOPASSWD sudo access for:
- `/sbin/pvesm` - Proxmox storage management
- `/sbin/qm` - Proxmox VM management
- `/usr/bin/tee /var/lib/vz/*` - Write to Proxmox storage directory

## Usage

### Run on all hosts:
```bash
ansible-playbook playbooks/add-system-user.yml -i inventory/proxmox.yml
```

### Run on specific hosts:
```bash
ansible-playbook playbooks/add-system-user.yml -i inventory/proxmox.yml --limit nexus_cluster
```

### Run on a single host:
```bash
ansible-playbook playbooks/add-system-user.yml -i inventory/proxmox.yml --limit bravo
```

### Override variables:
```bash
ansible-playbook playbooks/add-system-user.yml -i inventory/proxmox.yml \
  -e system_username=newuser \
  -e system_user_shell=/bin/zsh \
  -e authorized_keys_file=../files/myuser_authorized_keys
```

## What It Does

1. **Checks if user exists** - Verifies if the user already exists on the target system
2. **Creates user** - Creates the user with home directory (only if not exists)
3. **Creates .ssh directory** - Ensures proper directory exists with correct permissions (0700)
4. **Copies authorized_keys** - Copies the file from `files/terraform_authorized_keys` with correct permissions (0600)
5. **Creates sudoers file** - Adds `/etc/sudoers.d/<username>` with proper permissions
6. **Validates configuration** - Uses `visudo` to validate the sudoers file
7. **Tests passwordless sudo** - Runs `sudo pvesm apiinfo` to verify configuration works
8. **Provides summary** - Shows configuration details and test command

## Files Created

- `/home/<username>/` - User's home directory
- `/home/<username>/.ssh/` - SSH directory (mode 0700)
- `/home/<username>/.ssh/authorized_keys` - SSH public key (mode 0600)
- `/etc/sudoers.d/<username>` - Sudo configuration (mode 0440, validated)

## Verification

After the playbook runs, it will:
1. Test passwordless sudo by running: `sudo -u terraform sudo /sbin/pvesm apiinfo`
2. Display the output showing `APIVER` and `APIAGE`
3. Provide a command to test SSH from your local machine

### Manual Test

You can manually verify the configuration from your local machine:

```bash
# Test SSH connection and passwordless sudo
ssh terraform@<target-host> sudo pvesm apiinfo
```

**Expected output:**
```
APIVER 11
APIAGE 2
```

You should see this output **without being prompted for a password**. ✓

### What Success Looks Like

The playbook output will show:
```
Passwordless sudo test for terraform:
Status: SUCCESS ✓
Output: APIVER 11
        APIAGE 2
```

## Safety Features

- **Idempotent**: Safe to run multiple times
- **Validation**: Uses `visudo -cf` to validate sudoers syntax before applying
- **Proper permissions**: Sets correct ownership and modes on all files
- **User exists check**: Won't overwrite existing users
- **Live testing**: Verifies the configuration actually works before completing

## Customization

### Adding More SSH Keys

Simply edit the `files/terraform_authorized_keys` file and add more keys (one per line):

```bash
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINewKey..." >> files/terraform_authorized_keys
```

Then re-run the playbook to update all hosts.

### Changing Playbook Variables

Edit the `vars` section in the playbook to customize:
- Username
- Shell
- Comment/description
- Path to authorized_keys file
- List of sudo commands

## Example: Creating a Different User

```yaml
vars:
  system_username: "myuser"
  system_user_shell: "/bin/zsh"
  system_user_comment: "My custom user"
  authorized_keys_file: "../files/myuser_authorized_keys"
  sudoers_commands:
    - "/usr/bin/docker"
    - "/usr/bin/systemctl restart myservice"
```

## Troubleshooting

### "Passwordless Sudo: FAILED ✗"

If the passwordless sudo test fails:

1. **Check the sudoers file syntax:**
   ```bash
   ssh <target-host> sudo visudo -cf /etc/sudoers.d/terraform
   ```

2. **Check the sudoers file contents:**
   ```bash
   ssh <target-host> sudo cat /etc/sudoers.d/terraform
   ```

3. **Test sudo manually:**
   ```bash
   ssh <target-host>
   sudo -u terraform sudo /sbin/pvesm apiinfo
   ```

4. **Check sudo logs:**
   ```bash
   ssh <target-host> sudo tail -f /var/log/auth.log
   # or on some systems:
   ssh <target-host> sudo journalctl -u sudo -f
   ```

### "Permission denied (publickey)"

If SSH key authentication fails:

1. **Verify the SSH key was added:**
   ```bash
   ssh <target-host> sudo cat /home/terraform/.ssh/authorized_keys
   ```

2. **Check SSH directory permissions:**
   ```bash
   ssh <target-host> sudo ls -la /home/terraform/.ssh/
   # Should be: drwx------ (0700)
   ```

3. **Check authorized_keys permissions:**
   ```bash
   ssh <target-host> sudo ls -la /home/terraform/.ssh/authorized_keys
   # Should be: -rw------- (0600)
   ```

4. **Test with verbose SSH:**
   ```bash
   ssh -v terraform@<target-host> sudo pvesm apiinfo
   ```

### Re-running the Playbook

The playbook is idempotent and safe to run multiple times. To fix issues, simply re-run:
```bash
ansible-playbook playbooks/add-system-user.yml -i inventory/proxmox.yml --limit <failed-host>
```
