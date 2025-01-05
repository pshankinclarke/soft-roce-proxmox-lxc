# Udev Rules for RDMA Devices

By default, the `/dev/infiniband` device nodes may lack the necessary permissions for containerized processes to access RDMA functionality. Adjusting udev rules ensures that user-space applications inside LXC containers can interact with these devices seamlessly. 

As a quick disclaimer, here, I implement the simplest of approaches—giving devices `MODE="0666"`. It’s fine for quick lab setups, but it is inherently permissive. If you need a more secure setup, you might opt for group-based access or tighter permissions.


## Steps

1. **Create or Edit the Udev Rules File**

   Create a new udev rules file (or edit an existing one) at `/etc/udev/rules.d/40-rdma.rules`:
   
   ```bash
   nano /etc/udev/rules.d/40-rdma.rules
   ```

2. **Add Permission Rules**

   Add the following lines to make RDMA device nodes matching these patterns (e.g., `/dev/infiniband/uverbs0`) world-readable and writable (`0666`)
  
   ```
   KERNEL=="uverbs*", NAME="infiniband/%k", MODE="0666"
   KERNEL=="ucm*", NAME="infiniband/%k", MODE="0666"
   KERNEL=="rdma_cm", NAME="infiniband/%k", MODE="0666"
   ```

4. **Apply Changes**

   Reload the udev rules and trigger the updated configuration:
   
   ```bash
   udevadm control --reload-rules
   udevadm trigger
   ```

5. **Verify Permissions**

   Check the permissions of the `/dev/infiniband` devices:
   
   ```bash
   ls -l /dev/infiniband/
   ```
   
   You should see something like:
   
   ```
   crw-rw-rw- 1 root root 231, 64 Nov 17 10:00 uverbs0
   ```
   
   The `rw-rw-rw-` (0666) permissions confirm that any user, including those in containers, can access these devices.

---

**Next Steps:**  
With the udev rules configured, you can set up the LXC container itself. See [lxc_conf_example.md](./lxc_conf_example.md) for instructions on mounting `/dev/infiniband` inside the container and enabling correct memory limits for RDMA operations.
