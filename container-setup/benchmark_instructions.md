# Benchmarking Instructions

This covers how to measure RDMA latency and bandwidth in a containerized Soft-RoCE environment. It also includes notes on BIOS tuning, troubleshooting common issues, and parsing test results. These are the methods I've used in my own setup, and I hope that they're a helpful starting point. 

## Pre-Benchmark Configuration

### Hardware & Environment

- **System Model:** Dell Precision T1700 with a single Gigabit Ethernet NIC (*theoretical max throughput ~1 Gbps*).
- **Network:** Connected via an HPE J9979A (8‑port, Gigabit).
- **Power & CPU Settings:** Intel SpeedStep and C-states disabled for consistency; no CPU core pinning.
- **Proxmox Setup:** LXC containers, Soft-RoCE enabled on the host, etc.


### CPU and Power Management Settings

To avoid errors like,
``` 
Conflicting CPU frequency values detected: 3851.494000 != 3990.685000. CPU Frequency is not max.
```
...and to reduce variability in latency tests, disable dynamic CPU frequency scaling and power-saving states in your BIOS:

1. Disable **Intel SpeedStep Technology** (forces the CPU to run at maximum frequency).
2. Disable **C States Control** (prevents the CPU from entering low-power idle states).

## Common Error and MTU Considerations
If you encounter errors like:
```bash
Completion with error at client
Failed status 11: wr_id 0 syndrom 0x0
scnt=128, ccnt=0
```
This issue is often caused by mismatched MTU settings. To prevent it, I manually specify the message size in the example below.

## Latency Benchmarking

**On the server container (e.g., `px-server` at `192.168.101`):**

Start the server:
```bash
ib_send_lat -d rxe0 -s 3000
```
*(Adjust the `-s` for different message sizes. The server waits client connection.)*

**On the client container:**
Run the test:
```bash
ib_send_lat -d rxe0 -s 3000 192.168.1.101
```
The client sends RDMA operations to the server to measure round-trip latency.

### Automating Latency Tests
For repeated testing, automation [scripts](./scripts) can simplify the process. 
**On the server container:**
```bash
./run_ib_send_lat_server.sh
```
**On the client container:**
```bash
source /root/rdma_env/bin/activate
./run_ib_send_lat_client.sh
```
Results will aggregate into `rdma_latency_combined.txt`.

**Sample Output:**
```text
RDMA Latency Test Results
===================================
#bytes #iterations    t_min[usec] ...
64     10000          2.18         ...
...
```


**Parsing Results:**
Use the provided [Python script](./scripts/parse_rdma_latency.py) to parse and convert the results into a CSV file for analysis:
```bash
python parse_rdma_latency.py
```
The results are parsed into `rdma_latency_data.csv` for easier analysis. 

## Bandwidth Benchmarking

**MTU and RoCE MTU Limitations:**

In pratice, effective RoCE MTU is often capped at 4096 bytes(constrained to powers of two) even if the Ethernet MTU is set to 9000.

**Running a Bandwidth Test:**

**On the server:**
```bash
ib_send_bw -d rxe0 -s 3500
```
**On the client:**
```bash
ib_send_bw -d rxe0 -s 3500 192.168.1.101
```
Sample output:
```text
#bytes	#iterations	BW peak[MB/sec]	BW average[MB/sec]	MsgRate[Mpps]
3500	1000	765.57	746.19	0.223553
```

**Manual Adjustments and Data Collection:**

Coordinating matching MTU sizes and configurations can be challenging. To manage this, I manually ran tests for different message sizes (e.g., 1500, 2500, 3500 bytes) and recorded the results in a CSV file for comparison.

## Troubleshooting  

- **Hanging Server-Side Processes:**  
  When running benchmarks like `ib_send_bw` or `ib_send_lat`, the server process may occasionally hang after reporting its metrics. As a temporary workaround, record the metrics from the client, restart the server, and reconnect the client to continue testing. For more details, see the script [here](./scripts/).  

---

**Next Steps:**
Analyze your results with `parse_rdma_latency.py` to explore how different parameters (e.g., MTU, message size) impact performance. Benchmarking is an iterative process and there’s a lot to discover by experimenting with various configurations. For reference, here are my [latency](../benchmarks/latency/analysis.md) and [bandwidth](../benchmarks/bandwidth/analysis.md) results.

