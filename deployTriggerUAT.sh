#!/bin/bash
set -e

forge clean
rm -f .env
cp .env.uat .env
source .env
#forge script script/deploy_TracerTrigger.s.sol:deploy_TracerTrigger --rpc-url $RPC_URL --broadcast --verify -vvvvv --sig "run(string memory chain)" -- "UAT"
rm .env