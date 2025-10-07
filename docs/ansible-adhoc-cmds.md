# Ansible Adhoc Commands

## List all hosts

```bash
ansible all --list-hosts
```

## Ping all hosts

```bash
ansible all -m ansible.builtin.ping
```

## Ping a specific host

```bash
ansible alpha -m ansible.builtin.ping
```

## Get Facts

```bash
ansible all -m ansible.builtin.setup --limit 'alpha'
```

## Get Facts for a specific host

```bash
ansible alpha -m ansible.builtin.setup
```
