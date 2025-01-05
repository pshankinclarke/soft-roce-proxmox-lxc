#!/bin/bash

# Configuration Variables
SERVER_IP="10.2.27.191"
RDMA_DEVICE="rxe0"
ITERATIONS=10000
RUNS=10
OUTPUT_FILE="rdma_latency_combined.txt"
DELAY=2  # Delay in seconds between tests
MESSAGE_SIZE=64
# Initialize Output File
echo "RDMA Latency Test Results" > $OUTPUT_FILE
echo "===================================" >> $OUTPUT_FILE

# Loop to Run Multiple Tests
for i in $(seq 1 $RUNS); do
    echo "Starting test iteration $i..."

    # Run ib_send_lat Client Test
    ib_send_lat -d $RDMA_DEVICE -s $MESSAGE_SIZE -n $ITERATIONS $SERVER_IP >> $OUTPUT_FILE

    # Check if the test ran successfully
    if [ $? -eq 0 ]; then
        echo "Completed test iteration $i."
    else
        echo "Test iteration $i failed. Check server status."
        exit 1
    fi

    # Delay before the next test
    sleep $DELAY
done

echo "All tests completed. Results are saved in $OUTPUT_FILE."
