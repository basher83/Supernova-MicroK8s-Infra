# Issue Summary

I've identified the problem with VM 311 (microk8s-1). Here's what I found:

## The Issue:

• VM 311 is configured with IP 192.168.4.11/24 (ipconfig0: gw=192.168.4.1,ip=192.168.4.11/24)
• However, the network interface is connected to vmbr1 bridge
• vmbr1 is configured with the 192.168.11.0/24 subnet (address 192.168.11.2/24)
• This is a network mismatch - the VM is trying to use an IP from a different subnet than its bridge

## Why you can't ping it:

• The VM is on vmbr1 (192.168.11.x network) but trying to configure itself with 192.168.4.x
• The qemu-guest-agent can't be reached because the network isn't properly configured inside the VM

## Evidence:

• VM 311 config shows: net0: virtio=BC:24:11:B0:00:C5,bridge=vmbr1,firewall=0
• The host's vmbr1 is at 192.168.11.2/24
• VM is configured for 192.168.4.11/24 which doesn't match vmbr1's subnet
• The tap interface (tap311i0) is up but the VM likely has no working network

## Possible Solutions:

1. Change the VM's IP configuration to match vmbr1's subnet (192.168.11.x)
2. Change the VM's bridge from vmbr1 to the correct bridge that handles 192.168.4.x traffic
3. Check if there's routing or VLAN configuration missing on vmbr1

## Solution

Enable VLAN-aware bridging on all nodes and configure VM network interfaces with VLAN tag 2.

1. Phase 1: Enable VLAN-aware bridging on all nodes
   Enable VLAN filtering on vmbr1 bridge on each node (lloyd, mable, holly):

1. **Backup current network configuration**:

   ```bash
   cp /etc/network/interfaces /etc/network/interfaces.backup-$(date +%Y%m%d-%H%M%S)
   ```

1. **Edit /etc/network/interfaces** to add VLAN awareness to vmbr1:

   ```bash
   # Add this line under the vmbr1 configuration:
   bridge-vlan-aware yes
   ```

1. **Apply network changes**:

   ```bash
   ifreload -a
   ```

1. **Verify VLAN filtering is enabled**:
   ```bash
   ip -d link show vmbr1 | grep vlan_filtering
   # Should show: vlan_filtering 1
   ```

**Note**: This must be completed on all three nodes before proceeding to Phase 2.

2. Phase 2: Configure VM network interfaces with VLAN tag 2
   Modify each VM's network configuration to add VLAN tag 2:

**On node lloyd**:

- VM 311 (microk8s-1):
  ```bash
  qm set 311 -net0 virtio=BC:24:11:B0:00:C5,bridge=vmbr1,firewall=0,tag=2
  ```

**On node mable**:

- VM 312 (microk8s-2):
  ```bash
  qm set 312 -net0 virtio=BC:24:11:CD:AC:FE,bridge=vmbr1,firewall=0,tag=2
  ```

**On node holly**:

- VM 313 (microk8s-3):
  ```bash
  qm set 313 -net0 virtio=BC:24:11:7D:F0:D1,bridge=vmbr1,firewall=0,tag=2
  ```
- VM 399 (jumpbox-ansible-k8s):
  ```bash
  qm set 399 -net1 virtio=BC:24:11:0E:4F:65,bridge=vmbr1,firewall=0,tag=2
  ```

**Verify changes**:

```bash
qm config <VMID> | grep net
```

3. Phase 3: Restart VMs and verify connectivity
1. **Restart each VM** to apply network changes:

   ```bash
   # On lloyd
   qm restart 311

   # On mable
   qm restart 312

   # On holly
   qm restart 313
   qm restart 399
   ```

1. **Verify VLAN tagging on bridge**:

   ```bash
   bridge vlan show
   # Should show VLAN 2 on tap interfaces
   ```

1. **Test VM connectivity** (from within VMs or using qm agent):

   - Verify IPs: 192.168.4.11, 192.168.4.12, 192.168.4.13, 192.168.4.240
   - Test ping between VMs
   - Test qemu-guest-agent: `qm agent <VMID> network-get-interfaces`

1. **Monitor for issues**:
   ```bash
   journalctl -u pve-guests -f
   dmesg -w | grep vmbr1
   ```
1. Verify UniFi switch configuration
   Ensure the UniFi switch port connected to enp2s0f0np0 is properly configured:

1. **Port should be configured as trunk/tagged** with:

   - VLAN 2 allowed (tagged)
   - Native/untagged VLAN for 192.168.11.x traffic
   - Jumbo frames enabled (MTU 9000)

1. **Verify from Proxmox side**:

   ```bash
   # Check physical interface status
   ip link show enp2s0f0np0

   # Check bridge VLAN membership
   bridge vlan show dev enp2s0f0np0
   ```

**Note**: Without proper switch configuration, VMs won't be able to communicate on VLAN 2. 5. Rollback procedure (if needed)
If issues occur, follow these rollback steps:

1. **Remove VLAN tags from VMs**:

   ```bash
   # Example for VM 311
   qm set 311 -net0 virtio=BC:24:11:B0:00:C5,bridge=vmbr1,firewall=0
   ```

2. **Disable VLAN awareness on bridge**:

   ```bash
   # Edit /etc/network/interfaces
   # Remove: bridge-vlan-aware yes

   # Apply changes
   ifreload -a
   ```

3. **Restart affected VMs**:

   ```bash
   qm restart <VMID>
   ```

4. **Restore network backup if needed**:
   ```bash
   cp /etc/network/interfaces.backup-<timestamp> /etc/network/interfaces
   ifreload -a
   ```
