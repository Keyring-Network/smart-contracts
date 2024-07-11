# Keyring Contracts: Version 2.0

[![CI](https://github.com/Keyring-Network/core-v2/actions/workflows/ci.yml/badge.svg?event=push)](https://github.com/Keyring-Network/core-v2/actions/workflows/ci.yml)


This repo is built using Foundry.

## Table of Contents

- [Quickstart](#quickstart)
- [Local Development](#local-development)
- [Additional Documentation](#additional-documentation)
  - [Scripts](#scripts)
  - [Docker Files](#docker-files)

## Quickstart

The quickstart requires no system assumptions.

Build the Docker Images

```sh
bash bin/develop.sh
```

Start a Local Testnet in Docker

```sh
bash bin/testnet.sh
```

Run Solidity Tests in Docker

```sh
bash bin/tests.sh
```

## Local Development

For detailed documentation, visit: [Foundry Documentation](https://book.getfoundry.sh/)

Build Contracts
```shell
forge build
```
Run Tests
```shell
forge test
```
Gas Snapshots
```shell
forge snapshot
```
Deploy Contracts
```shell
forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Additional Documentation

### Scripts

For detailed descriptions and usage of the scripts, please refer to the [bin/README.md](bin/README.md).

### Docker Files

For more information on the Dockerfiles and Docker Compose configurations, please refer to the [dockerfiles/README.md](dockerfiles/README.md).