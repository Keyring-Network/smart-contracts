#!/bin/bash
set -e

forge clean
rm -f .env
cp .env.prod.zksync .env
source .env
#forge script script/upgrade_to_CoreV2_2.s.sol:upgrade_to_CoreV2_2 --zksync --rpc-url $RPC_URL --broadcast --verifier zksync --verifier-url https://zksync2-mainnet-explorer.zksync.io/contract_verification --verify -vvvvv --sig "run(string memory chain)" -- "ZKSYNC"
forge script script/upgrade_to_CoreV2_3.s.sol:upgrade_to_CoreV2_3 --zksync --rpc-url $RPC_URL --broadcast --verifier zksync --verifier-url https://zksync2-mainnet-explorer.zksync.io/contract_verification --verify -vvvvv --sig "run(string memory chain)" -- "ZKSYNC"
rm .env