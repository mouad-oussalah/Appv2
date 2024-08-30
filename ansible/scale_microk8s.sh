#!/bin/bash

# Function to scale MicroK8s
scale_microk8s() {
    local desired_replicas=$1
    local deployment_name="web"  # Replace with your actual deployment name

    # Scale the deployment
    microk8s kubectl scale deployment $deployment_name --replicas=$desired_replicas
}

# Get current day and time
day=$(date +%u)  # 1-7, 1 is Monday
hour=$(date +%H)

# Scale based on day and time
if [[ $day -le 5 ]]; then  # Weekday
    if [[ $hour -ge 8 && $hour -lt 18 ]]; then
        # Work hours: Monday to Friday, 08:00 to 18:00
        scale_microk8s 2  # Scale up to 2 replicas
    else
        # Off hours
        scale_microk8s 1  # Scale down to 1 replica
    fi
else
    # Weekend
    scale_microk8s 0  # Scale down to 0 replicas
fi