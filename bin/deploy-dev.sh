#!/bin/bash
set -e

# Help function
display_help() {
    echo "This script accepts the following command line arguments:"
    echo "-f: genesis file"
    echo ""
    
    echo "For example:"
    echo "bash bin/deploy-dev.sh -f ./genesis.json"
}

# Parse command-line arguments
while getopts :f:h flag
do
    case "${flag}" in
        f) ANVIL_GENESIS_FILE=${OPTARG};;
        h) display_help
           exit;;
        \?) echo "Invalid option: -${OPTARG}. Use -h or --help for more info. "
           exit 1;;
   esac
done

# Ensure jq is installed for JSON parsing
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq to continue."
    exit 1
fi

ANVIL_DEPLOY_PRV_KEY="0x024cf65eb3bc550a1a6675aa21d146d7476fc5b62715d24fb2e0027647a213af"
ANVIL_DEPLOY_PUB_KEY="0x7C010FD1B3e279ac063d862199484254f27C2C44"

# If genesis file is not provided, get from local repo directory
if [ -z "${ANVIL_GENESIS_FILE:-}" ]; then
    ANVIL_GENESIS_FILE="./genesis.json"
fi

# Ensure the genesis file contains the correct alloc for the deployer public key
GENESIS_CONTENT=$(jq ".alloc[\"${ANVIL_DEPLOY_PUB_KEY}\"] = {\"balance\": \"0xad78ebc5ac6200000\"}" "$ANVIL_GENESIS_FILE")
echo "$GENESIS_CONTENT" > "$ANVIL_GENESIS_FILE"

echo "Genesis file: $ANVIL_GENESIS_FILE"
echo "$GENESIS_CONTENT"

# get public key from private key
echo "Deployer private key: $ANVIL_DEPLOY_PRV_KEY"
echo "Deployer public key: $ANVIL_DEPLOY_PUB_KEY"

# Set environment variables for deployment
export ANVIL_DEPLOY_PRV_KEY
export ANVIL_DEPLOY_PUB_KEY
export RPC_URL="http://localhost:8545"

forge test

# Start Anvil in the background
anvil --host 0.0.0.0 --port 8545 --init $ANVIL_GENESIS_FILE --chain-id 1337 &

# Wait for avil node to be up and running on port 8545
spinner=( '⠏' '⠛' '⠹' '⢸' '⣰' '⣤' '⣆' '⡇' )

# Wait for anvil node to be up and running on port 8545
while ! (echo > /dev/tcp/localhost/8545) >/dev/null 2>&1; do
    for i in "${spinner[@]}"
    do
        echo -ne "\r$i waiting for anvil to start"
        sleep 0.2
    done
done

# Assumes ``$ forge build`` has already been run
# Deploy the contract using Forge
forge script script/unsafe.s.sol --rpc-url $RPC_URL --private-key $ANVIL_DEPLOY_PRV_KEY --broadcast

# Keep the container running
tail -f /dev/null