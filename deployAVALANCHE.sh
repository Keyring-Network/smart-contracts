#!/bin/bash
set -e

forge clean
rm -f .env
cp .env.prod.avalanche .env
source .env
#forge script script/deploy_CoreV2.s.sol:CoreV2Deploy --rpc-url $RPC_URL --broadcast --verify -vvvv
rm .env