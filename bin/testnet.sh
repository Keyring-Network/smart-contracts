#!/bin/bash

# This script builds Docker images for the core-v2 project and starts a local testnet.
# It ensures a clean environment by removing any existing testnet containers before starting a new one.

set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

docker build -t core-v2:latest -f "$ROOT/dockerfiles/core-v2.Dockerfile" .
docker build -t core-v2:testnet -f "$ROOT/dockerfiles/testnet.Dockerfile" .

# Remove Docker container if it exists
container_id=$(docker ps -a -q -f name=testnet)
if [ -n "$container_id" ]; then
    docker rm -f $container_id > /dev/null
fi

# Run the rest of the commands inside Docker container
docker compose -f dockerfiles/testnet.compose.yaml -p testnet-deployment up