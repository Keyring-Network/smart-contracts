# V2 Dockerfiles

Necessary configurations to build and manage Docker environments for the smart-contracts project, facilitating local development, testing, and deployment.

## Table of Contents

- [Dockerfiles](#dockerfiles)
  - [smart-contracts.base.Dockerfile](#smart-contractsbasedockerfile)
  - [smart-contracts.Dockerfile](#smart-contractsdockerfile)
  - [testnet.Dockerfile](#testnetdockerfile)
- [Docker Compose Files](#docker-compose-files)
  - [testnet.compose.yaml](#testnetcomposeyaml)

## Dockerfiles

### smart-contracts.base.Dockerfile

This Dockerfile sets up a lightweight Ubuntu 20.04 environment with necessary tools for Solidity development. It installs dependencies, sets the timezone, and installs Foundry (Forge and Cast). The project directory is prepared and dependencies are initialized using Forge.

**Usage:**

```bash
docker build -t smart-contracts:base -f dockerfiles/smart-contracts.base.Dockerfile .
```

### smart-contracts.Dockerfile

This Dockerfile builds upon the `smart-contracts:base` image to set up the environment for compiling and running the smart-contracts project. It compiles the Solidity contracts and includes all necessary project files for deployment and testing.

**Usage:**

```bash
docker build -t smart-contracts:latest -f dockerfiles/smart-contracts.Dockerfile .
```

### testnet.Dockerfile

This Dockerfile extends the `smart-contracts:latest` image to configure and run a local Anvil testnet node. It sets environment variables, exposes the testnet port, and runs the testnet configuration script to start the node.

**Usage:**

```bash
docker build -t smart-contracts:testnet -f dockerfiles/testnet.Dockerfile .
```

## Docker Compose Files

### testnet.compose.yaml

This Docker Compose file sets up a local testnet environment for deploying and testing smart contracts using smart-contracts. It defines two services:

- `node`: Runs a local RPC node for the testnet.
- `deploy-contracts`: Deploys smart contracts to the local testnet node.

**1. Build smart-contracts:base image:**

```bash
docker build -t smart-contracts:base -f dockerfiles/smart-contracts.base.Dockerfile .
```

**2. Build smart-contracts:latest image:**

```bash
docker build -t smart-contracts:latest -f dockerfiles/smart-contracts.Dockerfile .
```

**3. Build smart-contracts:testnet image:**

```bash
docker build -t smart-contracts:testnet -f dockerfiles/testnet.Dockerfile .
```

**4. Run the testnet environment:**

```bash
docker compose -f dockerfiles/testnet.compose.yaml -p testnet-deployment up
```
