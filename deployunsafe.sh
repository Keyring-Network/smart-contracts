#!/bin/sh

# Start Anvil in the background
anvil --host 0.0.0.0 --port 8545 &

# Wait for Anvil to start
sleep 5

# Set environment variables for deployment
export RPC_URL="http://localhost:8545"
export PRIVATE_KEY="0x024cf65eb3bc550a1a6675aa21d146d7476fc5b62715d24fb2e0027647a213af" #0x7C010FD1B3e279ac063d862199484254f27C2C44

# Compile the contracts
forge build

# Deploy the contract using Forge
forge script script/unsafe.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Keep the container running
tail -f /dev/null