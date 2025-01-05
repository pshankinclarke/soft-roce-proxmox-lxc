# Network Configuration for Soft-RoCE (RXE)

This section covers the host network configuration needed to enable Soft-RoCE (RXE) over a standard Ethernet interface. In this setup, a single standard Ethernet adapter (`eno1`) is bridged as `vmbr0` on a Proxmox host. The configuration includes setting up Jumbo Frames and creating RXE devices.

## Host Network 

The Proxmox host uses a Linux bridge (`vmbr0`) that is connected to the physical Ethernet interface (`eno1`). The bridge is assigned a static IP (`192.168.1.100`) and gateway (`192.168.1.1`), allowing multiple VMs or containers to share the physical network interface through `vmbr0`.

**Example `/etc/network/interfaces` configuration:**

```bash
# This file is managed by Proxmox and should generally not be edited directly.
# If you need custom configuration, you can use 'source' or 'source-directory'
# directives or modify bridge parameters via Proxmox's web interface.

auto lo
iface lo inet loopback

iface eno1 inet manual  # eno1 is set to manual, not assigned an IP directly

auto vmbr0
iface vmbr0 inet static
    address 192.168.1.100/24
    gateway 192.168.1.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0

source /etc/network/interfaces.d/*
```


## Jumbo Frames for Better RDMA Performance

For RDMA operations, increasing the MTU (Maximum Transmission Unit) to 9000 (Jumbo Frames) can improve bandwidth for RDMA workloads.

1. Set the MTU on the bridge and the underlying interface:
   ```bash
   ip link set dev vmbr0 mtu 9000
   ip link set dev eno1 mtu 9000
   ```

2. Verify the new MTU settings:
   ```bash
   ip link show vmbr0
   ip link show eno1
   ```
   You should see `mtu 9000` in the output for both interfaces.

## Configuring Soft-RoCE Without `rxe_cfg`

If the `rxe_cfg` utility is unavailable or tricky to build, you can configure RXE devices using the built-in `rdma link` command.

### Steps to Add an RXE Device

1. **Identify the network interface for RDMA:**
   
   List your network links:
   
   ```bash
   ip link show
   ```

   From the output, confirm the name of the interface that you want to use for RXE (e.g., `eno1`). This should be the physical interface, not the bridge.

2. **Add the RXE device:**
   
   ```bash
   rdma link add rxe0 type rxe netdev eno1
   ```
   
   This command creates a Soft-RoCE device named `rxe0` linked to the `eno1` network interface.

3. **Verify the RXE device status:**
   
   ```bash
   rdma link show
   ```
   
   Example output:
   
   ```
   link rxe0/1 state ACTIVE physical_state LINK_UP netdev eno1
   ```
   
   - `rxe0`: Name of the RXE device.
   - `ACTIVE` and `LINK_UP`: Says that the RXE device is ready for use.
   - `netdev eno1`: Confirms that `rxe0` is linked to the `eno1` interface.

---
At this point, the host is configured with a working RXE device over `eno1`, and Jumbo Frames are enabled to improve performance. The RXE device (`rxe0`) is now ready for use by your containers.

**Next Steps:**
- Configure udev rules to manage device permissions (see [udev_rules.md](./udev_rules.md))
- Update container settings to enable RDMA capabilities ([lxc_conf_example.md](./lxc_conf_example.md)).
- After set up, install RDMA tools in the containers to run latency and bandwidth tests.
