#!/bin/bash
set -e
source .env
forge script script/deploy/sepolia-non-upgradeable.s.sol:SepoliaCoreV2 --rpc-url $RPC_URL --broadcast --verify -vvvv