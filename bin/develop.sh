#!/bin/bash

# This script builds Docker images for the core-v2 project using various Dockerfiles.
# It ensures that the builds terminate on any error due to the `set -euo pipefail` directive.
#
# The built images are tagged as:
# - core-v2:base
# - core-v2:latest
# - core-v2:testnet
#
# Usage:
# Simply run the script from the command line:
#   bash develop.sh


set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

docker build -t smart-contracts:base -f "$ROOT/dockerfiles/smart-contracts.base.Dockerfile" .
docker build -t smart-contracts:latest -f "$ROOT/dockerfiles/smart-contracts.Dockerfile" .
docker build -t smart-contracts:testnet -f "$ROOT/dockerfiles/testnet.Dockerfile" .
