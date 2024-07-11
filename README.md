# Keyring Contracts: Version 2.0

[![CI](https://github.com/Keyring-Network/core-v2/actions/workflows/ci.yaml/badge.svg?event=push)](https://github.com/Keyring-Network/core-v2/actions/workflows/ci.yaml)


This repo is built using Foundry.

## Table of Contents

- [Quickstart](#quickstart)
  - [Build the Docker Images](#build-the-docker-images)
  - [Start a Local Testnet](#start-a-local-testnet)
  - [Configure and Start a Local Testnet](#configure-and-start-a-local-testnet)
  - [Deploy Smart Contracts](#deploy-smart-contracts)
  - [Run Solidity Tests in Docker](#run-solidity-tests-in-docker)
  - [Stop Testnet Service](#stop-testnet-service)
- [Documentation](#documentation)
- [Usage](#usage)
  - [Build Contracts](#build-contracts)
  - [Run Tests](#run-tests)
  - [Format Code](#format-code)
  - [Gas Snapshots](#gas-snapshots)
  - [Start Anvil](#start-anvil)
  - [Deploy Contracts](#deploy-contracts)
  - [Cast Commands](#cast-commands)
  - [Help](#help)
- [Additional Resources](#additional-resources)
  - [Scripts](#scripts)
  - [Docker Files](#docker-files)

## Quickstart

### Build the Docker Images

To build the necessary Docker images for the project, use the following script:

```sh
bash bin/develop.sh
```

### Start a Local Testnet

To build Docker images and start a local testnet environment, use:

```sh
bash bin/testnet.sh
```

### Configure and Start a Local Testnet

To configure and start a local Anvil testnet node with specific parameters, use:

```sh
bash bin/testnet-config.sh --host <HOST> --port <PORT> --chain <CHAIN_ID> --genesis <GENESIS_FILE> --fund-account <ACCOUNT>
```

### Deploy Smart Contracts

To deploy smart contracts to a specified Ethereum network, use:

```sh
bash bin/deploy.sh --rpc <RPC_URL> --chain <CHAIN_ID> --private-key <PRIVATE_KEY>
```

### Run Solidity Tests in Docker

To build the Docker image and run Solidity tests within a Docker container, use:

```sh
bash bin/tests.sh
```

### Stop Testnet Service

To stop the testnet service, use:

```sh
docker stop testnet
```

## Documentation

For detailed documentation, visit: [Foundry Documentation](https://book.getfoundry.sh/)

## Usage

### Build Contracts

```shell
forge build
```

### Run Tests

```shell
forge test
```

### Format Code

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Start Anvil

```shell
anvil
```

### Deploy Contracts

```shell
forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast Commands

```shell
cast <subcommand>
```

### Help

```shell
forge --help
anvil --help
cast --help
```

## Additional Resources

### Scripts

For detailed descriptions and usage of the scripts, please refer to the [bin/README.md](bin/README.md).

### Docker Files

For more information on the Dockerfiles and Docker Compose configurations, please refer to the [dockerfiles/README.md](dockerfiles/README.md).