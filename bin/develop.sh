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

docker build -t core-v2:base -f "$ROOT/dockerfiles/core-v2.base.Dockerfile" .
docker build -t core-v2:latest -f "$ROOT/dockerfiles/core-v2.Dockerfile" .
docker build -t core-v2:testnet -f "$ROOT/dockerfiles/testnet.Dockerfile" .