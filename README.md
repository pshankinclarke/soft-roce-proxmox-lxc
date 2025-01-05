# Soft-RoCE with Proxmox and LXC Containers

This repository walks through my process of setting up and testing **Soft-RoCE (RXE)** inside **Proxmox** LXC containers. It's a setup I’ve been experimenting with as I explore **RDMA** (Remote Direct Memory Access) and its potential in containerized environments—without needing specialized RDMA hardware. Limited by the hardware on hand, the setup uses a single **Dell Precision T1700** node running Proxmox, I host both server and client containers sharing the same `rxe` device attached to the host's Ethernet adapter. The steps here aren’t meant to be a definitive guide for every scenario; it's a work-in-progress intended for further exploration.

## Building Blocks of This Setup

- **Soft-RoCE (RXE):**  
  A software-based implementation of RDMA (Remote Direct Memory Access) that works over standard Ethernet NICs without the need for specialized RDMA hardware.
  
- **Proxmox LXC Containers:**  
  Lightweight Linux containers that share the host’s kernel. Once the host is RDMA-ready, these containers can run RDMA-aware applications without needing dedicated RDMA hardware. 

- **Host-only Tasks:**  
  Things that need direct kernel access, like loading modules, setting up RXE devices and configuring udev rules. 

- **Container Tasks:**  
  Installing RDMA user-space tools and running benchmarks to test latency and bandwidth.

## Configuration and Benchmarking Resources

- [Host Setup](./host-setup/host_config_steps.md):  
  Instructions for installing RDMA core utilities, loading kernel modules, configuring Soft-RoCE and networking, and setting up udev rules on the Proxmox host.

- [Container Setup](./container-setup/container_config.md):  
  Steps for installing RDMA user-space tools, checking RDMA device accessibility, and running basic tests like `ib_send_lat` and `ib_send_bw` in LXC containers.

- [Benchmarking](./benchmarks):  
  Benchmarks for latency and bandwidth:
  - [Latency Results](./benchmarks/latency/analysis.md)
  - [Bandwidth Results](./benchmarks/bandwidth/analysis.md)

## Network Diagram 

![RDMA vs TCP Bandwidth Comparison](./images/soft-roce-px.drawio.svg)

## Anomalies and Constraints

**Configuring Multiple Distinct RDMA Endpoints from a Single Ethernet Adapter**

The main challenge I’ve faced is hosting multiple independent RDMA endpoints on a single Ethernet adapter. The core issue is that all containers share the same underlying RXE device and therefore inherit its single GID, preventing them from acting as distinct RDMA endpoints. Configuring unique RDMA identities would require each container to have its own independent RXE device, which is not straightforward with a shared physical adapter. Here's what I've tried so far:


1. **Adding Multiple RXE Devices to a Single Adapter**  
   Attempting to create more than one RXE device (e.g., `rxe0` and `rxe1`) on a single underlying adapter (eno1) results in errors:
   ```bash
   rdma link add rxe0 type rxe netdev eno1
   rdma link add rxe1 type rxe netdev eno1
   error: File exists
   ```
   As far as I know, the RDMA subsystem won't allow duplicate RXE devices to share a single physical interface (`eno1`). 
   
2. **Using VLANs for RXE Devices:**  
   Attempting to use VLAN interfaces (e.g., eno1.20) as separate underlying devices for distinct RXE endpoints also fails:
   ```bash
   rdma link add rxe1 type rxe netdev eno1.20
   error: Operation not permitted
   ```
   It appears the RDMA subsystem doesn’t support VLAN sub-interfaces, because it requires a dedicated physical device.

This clearly limits the simulation of more ambitious virtualized networks with multiple containers. Because each container’s RXE device shares the same physical Ethernet adapter and endpoint, the configuration becomes more complex and might degrade overall performance. 

**Using `rdma link` Instead of `rxe_cfg`**

I’ve opted to use the `rdma link` command for configuring RXE devices due to challenges building `rxe_cfg`.`rdma link` involves a more hands-on configuration but is a convenient choice for now. For more details, see [Host Network Configuration](./host-setup/network_config.md)

**0 Peak Bandwidth**

When running `ib_send_bw` benchmarks, the server container sometimes reports `0.00 MB/Sec` for peak bandwidth, even though the client container shows results within the expected range. Otherwise, average bandwidth and other metrics remain closely matched between the two containers. For example:

**Server side:**
```
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[MB/sec]    BW average[MB/sec]   MsgRate[Mpps]
 65536      1000             0.00               552.05             0.008833
---------------------------------------------------------------------------------------
```
**Client side:**
```
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[MB/sec]    BW average[MB/sec]   MsgRate[Mpps]
 65536      1000             642.38             572.68             0.009163
---------------------------------------------------------------------------------------
```
It's unclear whether this behavior is expected with Soft-RoCE, a quirk of `ib_send_bw` prioritizing the client, or a result of mismatched configuration settings (e.g., queue depths, message sizes, or MTU) however in practice, it doesn't seem to affect overall throughput.
 
**Remote Access Error**

Occasionally, the following error appears while benchmarking:

```
 Completion with error at client (also occurs with `at server`)
 Failed status 11: wr_id 0 syndrom 0x0
```

The error seems to arise from mismatched configurations between the client and server, where one side attempts to access memory in a way the other doesn't permit. Matching configurations (message sizes, etc.) on both ends resolved the issue, though the exact cause remains unclear. 

 **Benchmarking Limitations**

This guide explores a specific virtualized configuration, notably without RDMA-specialized hardware or multiple Ethernet interfaces. Some aspects remain unresolved, limiting the scope of testing and benchmarking. For more, see the [benchmark pages](#configuration-and-benchmarking-resources).

**Hanging Server Side Processes**

When running benchmarks like `ib_send_bw` and latency `ib_send_lat`, the server process occasionally hangs after reporting its metrics. As a temporary fix, I record the metrics from the client, restart the server, and wait for the client to reconnect to continue testing. For more details, see the script [here](./container-setup/scripts/).


