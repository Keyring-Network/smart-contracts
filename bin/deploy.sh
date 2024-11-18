#!/bin/bash

# This script is used to deploy smart contracts to a specified Ethereum network.
# It accepts command line arguments for configuration and uses Foundry's Forge tool for deployment.
#
# Command Line Arguments:
# --rpc: The RPC URL of the network to which the contracts will be deployed (default: http://localhost:8545).
# --chain: The chain ID of the network (default: 1337).
# --private-key: The private key of the deployer account (default: 0x024cf65eb3bc550a1a6675aa21d146d7476fc5b62715d24fb2e0027647a213af).
# --help: Displays the help message with usage instructions.
#
# Example Usage:
# bash bin/deploy.sh --rpc http://localhost:8545 --chain 1337 --private-key 0x024cf65eb3bc550a1a6675aa21d146d7476fc5b62715d24fb2e0027647a213af
#
# Notes:
# - The script assumes that `forge build` has already been run and the contracts are compiled.
# - The script uses the `forge script` command to deploy the contract defined in `unsafe.s.sol`.
#
# The script will terminate on any error due to the `set -euo pipefail` directive.

set -euo pipefail

ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

# Default values
PRV_KEY="0x024cf65eb3bc550a1a6675aa21d146d7476fc5b62715d24fb2e0027647a213af"
RPC_URL=http://localhost:8545
CHAIN_ID=1337

# Help function
display_help() {
    echo "This script accepts the following command line arguments:"
    echo "--rpc: the network RPC"
    echo "--chain: the network chain id"
    echo "--private-key: The deployer private key"
    echo ""
    
    echo "For example:"
    echo "bash bin/deploy.sh --rpc $RPC_URL --chain $CHAIN_ID --private-key $PRV_KEY"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --rpc)
            RPC_URL="$2"
            shift 2
            ;;
        --chain)
            CHAIN_ID="$2"
            shift 2
            ;;
        --private-key)
            PRV_KEY="$2"
            shift 2
            ;;
        --help)
            display_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1. Use --help for more info."
            display_help
            exit 1
            ;;
    esac
done

# get public key from private key
echo "Deployer private key: $PRV_KEY"

# Assumes ``$ forge build`` has already been run
# Deploy the prod contract using Forge
forge script "$ROOT/script/nonupgradable.s.sol" --rpc-url $RPC_URL --private-key $PRV_KEY --broadcast

# Save the deployed contract address to a local file
addr=$(
    cast receipt --rpc-url $RPC_URL \
    $(
        cast bn --rpc-url $RPC_URL | \
        cast bl --rpc-url $RPC_URL --full --json | \
        jq '.transactions[0].hash' | \
        sed 's/"//g'
    ) \
    contractAddress
)
echo "Deployed contract address: $addr"
# save the address to a file for later use
echo $addr > "$ROOT/out-test/KeyringCoreV2.sol/KeyringCoreV2.address"
echo "Contract address saved to $ROOT/out-test/KeyringCoreV2.sol/KeyringCoreV2.address"

# Deploy the unsafe contract as well using Forge
forge script "$ROOT/script/unsafe.s.sol" --rpc-url $RPC_URL --private-key $PRV_KEY --broadcast

# Save the deployed contract address to a local file
addr=$(
    cast receipt --rpc-url $RPC_URL \
    $(
        cast bn --rpc-url $RPC_URL | \
        cast bl --rpc-url $RPC_URL --full --json | \
        jq '.transactions[0].hash' | \
        sed 's/"//g'
    ) \
    contractAddress
)
echo "Deployed contract address: $addr"
# save the address to a file for later use
echo $addr > "$ROOT/out-test/KeyringCoreV2Unsafe.sol/KeyringCoreV2Unsafe.address"
echo "Contract address saved to $ROOT/out-test/KeyringCoreV2Unsafe.sol/KeyringCoreV2Unsafe.address"

