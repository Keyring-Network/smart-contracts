#!/bin/bash
set -e

forge clean
rm -f .env
cp .env.prod.zksync .env
source .env
#forge script script/deploy_CoreV2.s.sol:CoreV2Deploy --zksync --rpc-url $RPC_URL --broadcast --verifier zksync --verifier-url https://zksync2-mainnet-explorer.zksync.io/contract_verification --verify -vvvv
rm .env