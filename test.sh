#!/bin/bash
set -e

rm -f .env
cp .env.test .env
forge clean
forge build
forge test -vvv -o out-test
forge clean
rm .env