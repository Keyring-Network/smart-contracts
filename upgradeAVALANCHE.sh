#!/bin/bash
set -e

forge clean
rm -f .env
cp .env.prod.avalanche .env
source .env
#forge script script/upgrade_to_CoreV2_2.s.sol:upgrade_to_CoreV2_2 --rpc-url $RPC_URL --broadcast --verify -vvvvv --sig "run(string memory chain)" -- "AVALANCHE"
forge script script/upgrade_to_CoreV2_3.s.sol:upgrade_to_CoreV2_3 --rpc-url $RPC_URL --broadcast --verify -vvvvv --sig "run(string memory chain)" -- "AVALANCHE"
rm .env