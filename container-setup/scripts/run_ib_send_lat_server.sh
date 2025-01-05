#!/bin/bash

# Configuration Variables
RDMA_DEVICE="rxe0"
ITERATIONS=10000
MESSAGE_SIZE=64
# Infinite Loop to Handle Multiple Client Connections
while true; do
    echo "************************************"
    echo "* Waiting for client to connect... *"
    echo "************************************"
    
    # Start ib_send_lat Server
    ib_send_lat -d $RDMA_DEVICE -s $MESSAGE_SIZE -n $ITERATIONS
    
    # Check Exit Status
    if [ $? -ne 0 ]; then
        echo "ib_send_lat encountered an error. Restarting server in 5 seconds..."
        sleep 5
    else
        echo "Client disconnected. Restarting server in 1 second..."
        sleep 1
    fi
done
