# LXC Container Configuration Example

To use RDMA features inside an LXC container, the container must have access to the RDMA device nodes (`/dev/infiniband`), allowed to lock sufficient memory, and optionally configured to use larger MTU sizes for better performance.

## Steps

1. **Edit the Container Configuration File**

   Replace `<CTID>` with your container’s ID:
   ```bash
   nano /etc/pve/lxc/<CTID>.conf
   ```

2. **Add Device and Cgroup Entries**

   Add the following lines to the container configuration file:
   
   ```conf
   # Bind-mount the RDMA device directory into the container’s filesystem
   lxc.mount.entry = /dev/infiniband dev/infiniband none bind,optional,create=dir

   # Grant access to RDMA character devices (major number 231)
   lxc.cgroup2.devices.allow = c 231:* rwm

   # Allow the container to lock unlimited memory (required by RDMA)
   lxc.prlimit.memlock: unlimited
   ```

   **What these do:**
   - `lxc.mount.entry`: Makes `/dev/infiniband` from the host accessible inside the container.
   - `lxc.cgroup2.devices.allow`: Permits the container the ability to interact with RDMA device nodes.
   - `lxc.prlimit.memlock: unlimited`: Removes memory lock limits required by RDMA.

3. **Enable Jumbo Frames (Optional)**

To optimize RDMA bandwidth, set a higher MTU (e.g., 9000):   
   ```conf
   net0: name=eth0,bridge=vmbr0,firewall=1,gw=10.2.27.1,hwaddr=BC:24:11:56:50:90,ip=10.2.27.192/24,type=veth,mtu=9000
   ```

   Check that the host’s network (host, switches, and other devices, if any) support Jumbo Frames. Matching the container’s MTU with the host and network devices can improve RDMA throughput.

4. **Restart the Container**

Apply the changes by restarting the container:
   
   ```bash
   pct stop <CTID>
   pct start <CTID>
   ```

5. **Verification**

   Inside the container:
   - Check that `/dev/infiniband` exists:
     ```bash
     ls /dev/infiniband
     ```
   - Verify that memory lock limits are now unlimited:
     ```bash
     ulimit -l
     ```
     The output should show `unlimited`.

**Next Steps:**
- Configure the host and containers (see [container_config.md](../container-setup/container_config.md)).
