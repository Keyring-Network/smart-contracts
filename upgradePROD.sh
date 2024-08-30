#!/bin/bash
set -e

forge clean
rm -f .env
cp .env.prod .env
source .env
forge script script/upgrade_to_CoreV2_2.s.sol:upgrade_to_CoreV2_2 --rpc-url $RPC_URL --broadcast --verify -vvvvv --sig "run(string memory chain)" -- "PROD"
rm .env