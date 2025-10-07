
## Option A — **ClusterCreator** (Terraform + Ansible + Proxmox + Unifi integration)

**What makes it stand out:**

* Automates VM and VLAN provisioning using **Terraform/OpenTofu** and **Ansible**, targeting Proxmox.
* Supports **Unifi network integration**, meaning you can manage VLANs and networking all in one place.
* Offers advanced features like:

  * HA control plane with **kube-VIP**
  * Dual-stack (IPv4/IPv6) networking
  * Custom worker node classes (cpu/memory/disk)
  * External etcd for resilience
  * Dynamic scaling and flexible cluster management
  * Helm chart add-ons (metrics server, Cilium CNI, etc.)
    ([GitHub][1], [HRNPH BLOG][2], [Reddit][3])

> From r/homelab:
> “Now, with just two commands, I can provision large, managed kubeadm clusters in minutes!”
> — user benbutton1010
> ([Reddit][3])

This gives you the most dynamic, production-like flexibility—and **the Unifi VLAN integration is a big win** if you're juggling traffic isolation or segmented networks.

---

## Option B — **hrnph’s MicroK8s on Proxmox** (Terraform + Ansible + MicroK8s + Rancher + Argo CD)

**Why it’s appealing:**

* Focuses on **MicroK8s**, aligning perfectly with your “Apollo” vision—lightweight, HA-capable K8s.
* Includes **Rancher** and **Argo CD** for cluster and GitOps management.
* Adds a **jumpbox** for secure, isolated cluster access and minimal LAN footprint.
* Automates everything via Terraform (for VMs) and Ansible (for cluster configuration).
* Strong emphasis on isolation, security, and clean architecture.
  ([Cyber-Engine][4], [HRNPH BLOG][2])

**Ideal if:**

* You’re most focused on a clean, minimal infrastructure with polished UI tooling.
* You prefer working with MicroK8s and want a tight, secure homelab cluster.

---

## Quick Side-by-Side

| Criteria                    | ClusterCreator                                  | hrnph’s MicroK8s-IaC                                |
| --------------------------- | ----------------------------------------------- | --------------------------------------------------- |
| **MicroK8s**                | Not the default (kubeadm-oriented)              | Core focus—perfect for your “Apollo” setup          |
| **Unifi VLAN integration**  | Yes                                             | No                                                  |
| **HA networking & scaling** | Highly flexible, external etcd, dual-stack etc. | Simpler, more controlled setup                      |
| **Cluster UI Tools**        | Helm charts (metrics, Cilium, etc.)             | Rancher + Argo CD built-in                          |
| **Security & Isolation**    | Solid, with VLANs                               | Advanced—jumpbox, private network, limited exposure |
| **Complexity/Onboarding**   | Steeper learning curve                          | Clean and structured, easier progression            |

---

## How to Decide

* **Want powerful flexibility + network control (Unifi VLANs, custom node classes, HA quirks)?**
  → **Go with ClusterCreator**.

* **Want a clean, fast-to-deploy MicroK8s cluster with modern tooling and tighter security?**
  → **Start with hrnph’s MicroK8s-IaC project**.

* **Can’t choose?** You can even stitch them together—use ClusterCreator’s infrastructure capabilities (like VLANs and templating) and swap kubeadm for MicroK8s in the Ansible playbooks. Hello, best of both worlds.

---

## Next Move

1. Dive into **ClusterCreator’s GitHub & blog** to explore the code and docs (Unifi integration + VLAN automation).
2. Peek at **hrnph’s tutorial** for a damn clean MicroK8s, Rancher, Argo CD flow.
3. Decide your priority:

   * If **network complexity + flexibility** rules → ClusterCreator.
   * If **simplicity, MicroK8s, UI tooling, and isolation practices** are key → hrnph’s route.

[1]: https://github.com/christensenjairus/ClusterCreator?utm_source=chatgpt.com "ClusterCreator: Terraform & Ansible K8s on Proxmox"
[2]: https://blog.hrnph.dev/posts/k8s-ansible-terraform-proxmox-tutorial/?utm_source=chatgpt.com "Isolated Kubernetes Cluster on Proxmox with Terraform and ..."
[3]: https://www.reddit.com/r/homelab/comments/1fcui9f/fully_functional_k8s_on_proxmox_using_terraform/?utm_source=chatgpt.com "Fully Functional K8s on Proxmox using Terraform and ..."
[4]: https://cyber-engine.com/blog/2024/06/25/k8s-on-proxmox-using-clustercreator/?utm_source=chatgpt.com "Introducing ClusterCreator: K8s on Proxmox using Terraform ..."
