#!/bin/bash
set -e

rm -f .env
cp .env.test .env
forge clean
forge build
# TEST FOR ZKSYNC
#forge test --zksync -vvv -o out-test # THIS WILL FAIL THE RSA AND E2E TEST. THAT IS EXPECTED AS THERE IS NO MODEXP PRECOMPILE
# NORMAL TEST - THIS INCLUDES ZKSYNC TESTS, BUT DOES NOT EMULATE FULL ZKSYNC ENVIRONMENT
forge test -vvv -o out-test
forge clean
rm .env