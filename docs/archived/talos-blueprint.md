## Talos-Voyager Homelab Blueprint

### 1. Talos Linux Setup (Immutable, API-Driven OS)

* **Install `talosctl`** (your primary admin interface—no SSH, no mess): boot nodes via Talos ISO (runs in RAM), then apply configs to install the OS on disk. ([Xeiaso][1], [TALOS LINUX][2])
* **Generate machine configs** (control plane + workers) using `talosctl gen config`, including install disk, networking, and hostname declarations. ([TALOS LINUX][2])
* **Apply configs** to each node with `talosctl apply-config` (control plane first, then workers), then run `talosctl bootstrap` to initialize your etcd/Kubernetes cluster. ([TALOS LINUX][2])
* **Access & manage** cluster via `talosctl`, no shell access required—API-only, declarative, minimal-attack surface. ([Daly Days Blog][3])

---

### 2. Install RKE2 Kubernetes

* On control plane nodes:

  ```bash
  curl -sfL https://get.rke2.io | sh -
  sudo systemctl enable --now rke2-server
  ```
* On worker nodes:

  ```bash
  curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -
  sudo systemctl enable --now rke2-agent
  ```
* These steps deliver a hardened, fully conformant Kubernetes—complete with kubeconfig, install token, and automation. ([RKE2 Docs][4], [Xeiaso][1])

---

### 3. Core Add-ons (Prod-like Stack Without the Hassle)

| Component        | Role                                    |
| ---------------- | --------------------------------------- |
| **Cilium**       | eBPF-powered CNI, observability, secure |
| **MetalLB**      | L2 LoadBalancer for external services   |
| **cert-manager** | Automated TLS certificates              |
| **Longhorn**     | Simple replicated block storage         |

* **Cilium**: Helm-installable, brings load balancing, network policies, and visibility to your RKE2 cluster. ([TALOS LINUX][5], [Reddit][6], [RKE2 Docs][4])
* **MetalLB** and **cert-manager** enable external service exposure with IPs and TLS. ([Daly Days Blog][3], [Medium][7])
* **Longhorn** (optional but recommended) for dynamic PVs.

---

### 4. Real-World Homelab Playbook

Want structure? Here’s your pre-flight checklist:

1. **Plan layout**: 3 control-plane nodes (quorum) + 2–3 workers (your compute scale, your call).
2. **Generate Talos configs**: Include custom disks, IPs, hostnames, network/gateway DNS entries. ([Linux.com][8])
3. **Install Talos**: Boot each node via ISO, apply configs (`apply-config`), then bootstrap the control plane.
4. **Install RKE2**: Run installer on CPs, join agents via token.
5. **Add add-ons** in this order:

   * Cilium for connectivity
   * MetalLB + `IPAddressPool` for external IPs
   * `cert-manager` for TLS
   * Longhorn for storage
6. **Management plane**: Optionally install Rancher for slick UI and multi-cluster control.

---

## Why This Works

* **Immutable control**: Talos locks down OS changes—you can upgrade declaratively, rollback confidently.
* **Secure operations**: API-only access keeps attack surface tiny.
* **Prod aesthetic**: RKE2 + Cilium mirror enterprise patterns.
* **Minimal yak shaving**: Each tool is modular, well-documented, and your compute cushion isn’t stressed.

---

[1]: https://xeiaso.net/notes/2024/homelab-v2/03/?utm_source=chatgpt.com "Rebuilding the homelab: The Talos Principle"
[2]: https://www.talos.dev/v1.10/introduction/getting-started/?utm_source=chatgpt.com "Getting Started"
[3]: https://blog.dalydays.com/post/kubernetes-homelab-series-part-1-talos-linux-proxmox/?utm_source=chatgpt.com "Kubernetes Homelab Series Part 1 - Introduction and Talos ..."
[4]: https://docs.rke2.io/install/quickstart?utm_source=chatgpt.com "Quick Start"
[5]: https://www.talos.dev/v1.0/introduction/getting-started/?utm_source=chatgpt.com "Getting Started"
[6]: https://www.reddit.com/r/kubernetes/comments/1myb8xc/lab_setup_3node_talos_cluster_mac_minis_minio/?utm_source=chatgpt.com "[Lab Setup] 3-node Talos cluster (Mac minis) + MinIO ..."
[7]: https://medium.com/%40josephsims1/homelab-setup-running-rke2-and-okd-on-almalinux-5d98bba3783f?utm_source=chatgpt.com "Homelab Setup: Running RKE2 and OKD on AlmaLinux"
[8]: https://www.linux.com/thelinuxfoundation/a-simple-way-to-install-talos-linux-on-any-machine-with-any-provider/?utm_source=chatgpt.com "A Simple Way to Install Talos Linux on Any Machine, with ..."
