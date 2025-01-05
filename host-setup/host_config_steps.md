# Host Configuration Steps

This outlines the steps to configure the Proxmox host to support Soft-RoCE (RXE). Once the host is set up, the LXC containers can access RDMA capabilities provided by the host kernel.

## Prerequisites

- A Proxmox host (e.g., `px-host`) running a recent kernel that supports RDMA and RXE.
- Administrative (root) access to the host.
- A working Ethernet interface (e.g., `eno1`) connected to the network.


**Host Details:**

- Example Host: `px-host`
- CPU: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz (1 Socket, 8 cores)
- Kernel: `Linux 6.8.12-4-pve`
- Boot Mode: EFI
- Proxmox Version: `pve-manager/8.3.0/c1689ccb1065a83b`

## Steps

### 1. Install and Load RDMA Kernel Modules

First, ensure that the RDMA core utilities are installed. 

```bash
apt-get update
apt-get install -y rdma-core
```

Manually load kernel modules to activate the Soft-RoCE stack:

```bash
modprobe rdma_cm
modprobe ib_uverbs
modprobe rdma_rxe
```
> **Note:** If you prefer to load these modules automatically after reboot, you can add them to `/etc/modules`(one line per module).

#### Verification

```bash
lsmod | grep -E "rdma_cm|ib_uverbs|rdma_rxe"
```

### 2. Configure Soft-RoCE (RXE)

Attach an RDMA device (`rxe0`) to a host Ethernet interface to enable Soft-RoCE.

For more detailed steps, refer to [network_config.md](./network_config.md) .

### 3. Udev Rules for Device Access

By default, `/dev/infiniband/*` devices may have restricted permissions for use inside LXC containers. Update udev rules to ensure containers have access.

See [udev_rules.md](./udev_rules.md) for details.

### 4. LXC Container Configuration

To allow RDMA device access and enable memory locking within your LXC containers, update their configuration files.

Refer to [lxc_conf_example.md](./lxc_conf_example.md) for an example configuration snippet.

