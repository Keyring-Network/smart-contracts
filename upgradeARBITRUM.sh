#!/bin/bash
set -e

forge clean
rm -f .env
cp .env.prod.arbitrum .env
source .env
#forge script script/upgrade_to_CoreV2_2.s.sol:upgrade_to_CoreV2_2 --rpc-url $RPC_URL --broadcast --verify -vvvvv --sig "run(string memory chain)" -- "ARBITRUM"
#forge script script/upgrade_to_CoreV2_3.s.sol:upgrade_to_CoreV2_3 --rpc-url $RPC_URL --broadcast --verify -vvvvv --sig "run(string memory chain)" -- "ARBITRUM"
# ABOVE THIS LINE ALREADY RUN FOR THIS ENVIRONMENT
forge script script/upgrade_to_CoreV2_4.s.sol:upgrade_to_CoreV2_4 --rpc-url $RPC_URL --broadcast --verify -vvvvv --sig "run(string memory chain)" -- "ARBITRUM"
rm .env