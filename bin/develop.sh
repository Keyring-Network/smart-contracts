#!/bin/bash

# This script builds Docker images for the core-v2 project using various Dockerfiles.
# It ensures that the builds terminate on any error due to the `set -euo pipefail` directive.
#
# Steps Performed:
# 1. Determines the root directory of the project based on the location of the script.
# 2. Builds the Docker image for the core-v2 base environment using `core-v2.base.Dockerfile`.
# 3. Builds the Docker image for the core-v2 latest environment using `core-v2.Dockerfile`.
# 4. Builds the Docker image for the core-v2 testnet environment using `testnet.Dockerfile`.
#
# The built images are tagged as:
# - core-v2:base
# - core-v2:latest
# - core-v2:testnet
#
# Usage:
# Simply run the script from the command line:
#   bash develop.sh
#
# Notes:
# - Make sure Docker is installed and running on your system.
# - The script assumes that the Dockerfiles are located in the `dockerfiles` directory
#   within the root directory of the project.
# - The script uses the `dirname` and `realpath` commands to determine the root directory.


set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

docker build -t core-v2:base -f "$ROOT/dockerfiles/core-v2.base.Dockerfile" .
docker build -t core-v2:latest -f "$ROOT/dockerfiles/core-v2.Dockerfile" .
docker build -t core-v2:testnet -f "$ROOT/dockerfiles/testnet.Dockerfile" .