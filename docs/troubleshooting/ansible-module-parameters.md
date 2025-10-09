# Debugging Ansible Module Parameters

When encountering errors with Ansible modules (especially collection modules), use this systematic approach to identify correct parameter usage.

## The Tools

### 1. `ansible-doc` - First Line of Defense

Fast, built-in documentation showing module parameters, types, and examples.

```bash
# View module documentation
ansible-doc community.proxmox.proxmox_user

# View just the examples section
ansible-doc community.proxmox.proxmox_user | grep -A 30 "EXAMPLES:"

# List available modules in a collection
ansible-doc -l community.proxmox
```

**Best for:**
- Quick parameter reference
- Understanding required vs optional parameters
- Seeing common usage patterns in EXAMPLES section

**Limitations:**
- May not clarify all edge cases
- Sometimes unclear about parameter relationships
- Documentation can lag behind implementation

### 2. Source Code Inspection - Ground Truth

Direct examination of module source code for definitive answers.

```bash
# Find module location
ansible-doc -l | grep module_name

# Read the module source
# For community collections:
cat ~/.ansible/collections/ansible_collections/NAMESPACE/COLLECTION/plugins/modules/MODULE.py

# Example:
cat ~/.ansible/collections/ansible_collections/community/proxmox/plugins/modules/proxmox_user.py
```

**Best for:**
- Resolving ambiguity about parameter existence
- Understanding parameter aliases (e.g., `name` vs `userid`)
- Seeing exact validation logic and defaults
- Finding undocumented behavior

**Limitations:**
- Slower to navigate
- Requires Python knowledge to interpret
- More detail than usually necessary

## Troubleshooting Strategy

### Step 1: Check `ansible-doc` examples

```bash
ansible-doc community.proxmox.proxmox_access_acl | grep -A 30 "EXAMPLES:"
```

Look for:
- Parameter structure (dict, list, string)
- Required vs optional parameters
- Common patterns

**Example finding:** `proxmox_access_acl` examples showed `type: group`, `ugid`, and `roleid` as individual parameters, not arrays.

### Step 2: Verify parameter names and types

```bash
ansible-doc community.proxmox.proxmox_user | grep -E "^\s+(userid|name|realm)"
```

Check:
- Exact parameter names (case-sensitive)
- Data types (str, list, dict, bool, int)
- Aliases (`userid` has alias `name`)

### Step 3: Consult source code when uncertain

Read the `DOCUMENTATION` section in the module source:

```python
options:
  userid:
    description:
      - The user name.
      - Must include the desired PVE authentication realm.
    type: str
    aliases: ["name"]
    required: true
```

**Example finding:** `proxmox_user` source code definitively showed no separate `realm` parameter exists - the realm must be included in `userid` as `username@realm`.

### Step 4: Check EXAMPLES in source code

Source code examples often show more patterns than `ansible-doc`:

```python
EXAMPLES = r"""
- name: Create new Proxmox VE user
  community.proxmox.proxmox_user:
    name: user@pve    # Shows realm included in name/userid
    groups:
      - admins        # Shows groups as list of strings
"""
```

## Common Issues and Solutions

### Issue: "Unknown parameter" error

**Cause:** Parameter doesn't exist or is misspelled

**Solution:**
1. Check `ansible-doc MODULE` for exact parameter names
2. Look for aliases in source code
3. Verify you're using the correct module version

### Issue: "Required parameter missing" error

**Cause:** Module requires specific parameter format

**Solution:**
1. Check source code for `required: true` parameters
2. Look for `required_one_of` or `required_together` in module definition
3. Example: `proxmox_user` requires `userid` (or alias `name`)

### Issue: Module fails with format error

**Cause:** Wrong data type or structure

**Solution:**
1. Check parameter type in `ansible-doc`: `type: list` vs `type: str`
2. Verify structure in EXAMPLES
3. Example: `proxmox_access_acl` expects `type: group` and `ugid: name`, not `groups: [name]`

## Quick Reference

| Tool | Speed | Accuracy | Best Use Case |
|------|-------|----------|---------------|
| `ansible-doc` | Fast | High | Initial parameter lookup, examples |
| Source code | Slow | Definitive | Resolving ambiguity, confirming parameter existence |

## Best Practices

1. **Start with `ansible-doc`** - covers 90% of cases
2. **Read EXAMPLES first** - shows real-world usage patterns
3. **Check source code when:**
   - Documentation is unclear
   - Error messages contradict documentation
   - You need to verify parameter doesn't exist
4. **Test incrementally** - verify one parameter change at a time
5. **Use `--check` mode** - test changes without applying them

## Example Workflow

```bash
# 1. Quick parameter check
ansible-doc community.proxmox.proxmox_user | grep -A 5 "userid"

# 2. View examples
ansible-doc community.proxmox.proxmox_user | grep -A 30 "EXAMPLES:"

# 3. If still unclear, check source
cat ~/.ansible/collections/ansible_collections/community/proxmox/plugins/modules/proxmox_user.py | grep -A 10 "options:"

# 4. Test with check mode
ansible-playbook playbook.yml --check --diff
```
