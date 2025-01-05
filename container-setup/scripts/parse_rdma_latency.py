import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

with open('rdma_latency_combined.txt', 'r') as file:
    lines = file.readlines()

data = []
columns = ['Bytes', 'Iterations', 'Min_usec', 'Max_usec', 'Typical_usec', 'Avg_usec', 'StdDev_usec', 'P99_usec', 'P999_usec']

# Iterate through lines to handle multiple data blocks
for i, line in enumerate(lines):
    # Check for header line, stripping leading/trailing whitespace
    if line.strip().startswith("#bytes"):
        # Iterate over subsequent lines to collect data
        for data_line in lines[i+1:]:
            # Stop if we reach a separator or another header
            if data_line.strip() == '' or data_line.strip().startswith("#bytes") or data_line.strip().startswith('--------------------------------------------------------------------------------'):
                break
            parts = data_line.split()
            if len(parts) < 9:
                continue  # Skip incomplete lines
            try:
                bytes_sent = int(parts[0])
                iterations = int(parts[1])
                t_min = float(parts[2])
                t_max = float(parts[3])
                t_typical = float(parts[4])
                t_avg = float(parts[5])
                t_stdev = float(parts[6])
                p99 = float(parts[7])
                p999 = float(parts[8])
                data.append([bytes_sent, iterations, t_min, t_max, t_typical, t_avg, t_stdev, p99, p999])
            except ValueError as ve:
                print(f"ValueError: {ve} in line: {data_line.strip()}")
                continue  # Skip lines with invalid data

# Check if any data was collected
if not data:
    print("No data found in the file. Check the file format and content.")
    exit(1)

df = pd.DataFrame(data, columns=columns)

# Save to CSV for presentation
df.to_csv('rdma_latency_data.csv', index=False)


