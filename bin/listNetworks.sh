#!/bin/bash


set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

# Check for invalid network names
INVALID_NAMES=$(ls -1 "$ROOT/networks" | sed 's/\.txt$//' | grep -v '^[A-Z][A-Z0-9-]*$' || true)

if [ ! -z "$INVALID_NAMES" ]; then
    echo "Error: The following network names are not properly formatted (should be all uppercase letters, numbers, and hyphens):"
    echo "$INVALID_NAMES"
    exit 1
fi

# If all valid, list the networks
ls -1 "$ROOT/networks" | sed 's/\.txt$//'



