# Container-Side Configuration

Once the host is configured for Soft-RoCE (RXE) and RDMA device nodes are accessible to the LXC containers, each container needs some additional configuration to make use of RDMA. Here, we have two containers:

- **Server container:** `px-server`
- **Client container:** `px-client`

Both containers are configured similarly with the following resources:

- Memory: 1.50 GiB
- Swap: 2.00 GiB
- Cores: 2
- Root Disk: `local-lvm:vm-101-disk-0,size=16G`

## Example Network Configuration 

**Inside `px-server`** (`/etc/network/interfaces`):
```bash
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.1.101/24
    gateway 192.168.1.1
    mtu 9000
```
**Inside `px-client`** (`/etc/network/interfaces`):
```bash
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.1.102/24
    gateway 192.168.1.1
    mtu 9000
```
> **Note:** Make sure both containers use the same gateway and MTU, but each has its own unique IP address. 

## Installing RDMA Tools Inside the Container

Once the container can access the RDMA devices from the host, install the necessary user-space RDMA utilities:

```bash
apt-get update
apt-get install -y rdma-core ibverbs-utils infiniband-diags rdmacm-utils perftest
```

This provides tools like (`ib_send_lat`, `ib_send_bw`, etc.) for benchmarking RDMA.

### Additional Tools and Development Packages

If you need more advanced tools or plan to develop RDMA-based applications, install the following:

```bash
apt-get install -y build-essential pkg-config vlan automake autoconf dkms git
apt-get install -y libibverbs-dev librdmacm-dev libibmad-dev libibumad-dev
apt-get install -y libtool ibutils ibverbs-utils rdmacm-utils infiniband-diags perftest
apt-get install -y numactl libnuma-dev libnl-3-200 libnl-route-3-200 libnl-route-3-dev libnl-utils
```

To ensure you've covered any missing libraries,consider using a wildcard search:
```bash
sudo apt-get install -y libibverbs* librdma* libibmad.* libibumad*
```

---

## Verification Steps

After installing the tools, verify that the RDMA devices and network are working correctly:

**Check for RDMA Devices:**
```bash
ibv_devices
ibv_devinfo
```
You should see the `rxe0` device (or whichever name you assigned) listed.

**Resource Verification:**

```bash
rdma res show
```
A successful output might look like this:
```
0: rxe_eno1: pd 2 cq 1 qp 1 cm_id 1 mr 0 ctx 1 srq 0
```
This indicates that RDMA resources are recognized and available.

**Verify Network Connectivity:**
Test basic network connectivity by pinging the container’s IP or the host

```bash
ping 192.168.1.101
```
---

## Next Steps

With the containers configured and RDMA tools installed, you're ready to run RDMA performance tests (see [bechmark_instructions.md](./benchmark_instructions.md)). Start with `ib_send_lat` for latency benchmarks and `ib_send_bw` for bandwidth benchmarks. Tweaking parameters like message size (`-s`) and enabling Jumbo Frames can help optimize performance. 
