#!/bin/bash

set -e

docker build -t core-v2:latest -f dockerfiles/deploy.Dockerfile .

# Remove Docker container if it exists
container_id=$(docker ps -a -q -f name=core-v2)
if [ -n "$container_id" ]; then
    docker rm -f $container_id > /dev/null
fi

# Run the rest of the commands inside Docker container
pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null
docker run \
    --name core-v2 \
    -p 8545:8545 \
    core-v2:latest \
    bash ./bin/deploy-dev.sh
popd