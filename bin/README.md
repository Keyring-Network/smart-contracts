Scripts for building, deploying, and managing the `smart-contracts` project.

## Table of Contents

- [Requirements](#requirements)
- [Scripts](#scripts)
  - [Deploy Smart Contracts (`deploy.sh`)](#deploy-smart-contracts-deploysh)
  - [Build Docker Dev Environments (`develop.sh`)](#build-docker-dev-environments-developsh)
  - [Start a Testnet in a Shell (`testnet-config.sh`)](#start-a-testnet-in-a-shell-testnet-configsh)
  - [Build Env and Start Testnet in Docker (`testnet.sh`)](#build-env-and-start-testnet-in-docker-testnetsh)
  - [Run Solidity Tests (`tests.sh`)](#run-solidity-tests-testssh)


## Requirements 
- `docker`
- `jq` for `testnet-config.sh`

## Scripts

### Deploy Smart Contracts (`deploy.sh`)

This script deploys smart contracts to a specified Ethereum network using Foundry's Forge tool.

**Usage:**
```bash
bash bin/deploy.sh --rpc <RPC_URL> --chain <CHAIN_ID> --private-key <PRIVATE_KEY>
```
**Options:**
- `--rpc`: The RPC URL of the network.
- `--chain`: The chain ID of the network.
- `--private-key`: The private key of the deployer account.
- `--help`: Display help message with usage instructions.

### Build Docker Dev Environments (`develop.sh`)

Builds Docker images for the `smart-contracts` project and sets up the development environment.

**Usage:**
```bash
bash bin/develop.sh
```

### Configure and Start a Testnet (`testnet-config.sh`)

Configures and starts a local Anvil testnet node with the specified parameters.

**Usage:**
```bash
bash bin/testnet-config.sh --host <HOST> --port <PORT> --chain <CHAIN_ID> --genesis <GENESIS_FILE> --fund-account <ACCOUNT>
```
**Options:**
- `--host`: Testnet host.
- `--port`: Testnet port.
- `--chain`: Testnet chain ID.
- `--genesis`: Path to the genesis file.
- `--fund-account`: Account to be funded in the genesis file.
- `--help`: Display help message with usage instructions.

### Build Env and Start Testnet in Docker (`testnet.sh`)

Builds Docker images and starts a local testnet environment for the `smart-contracts` project.

**Usage:**
```bash
bash bin/testnet.sh
```

### Run Solidity Tests (`tests.sh`)

Builds the `smart-contracts` Docker image and runs Solidity tests within a Docker container.

**Usage:**
```bash
bash bin/tests.sh
```