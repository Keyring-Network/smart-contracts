#!/bin/bash
set -e

rm -f .env
cp .env.test .env
forge clean
forge build
#forge test test/RsaVerifyTest.t.sol --zksync -vvv -o out-test
forge test -vvv -o out-test
forge clean
rm .env