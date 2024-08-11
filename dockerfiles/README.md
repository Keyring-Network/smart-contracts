# V2 Dockerfiles

Necessary configurations to build and manage Docker environments for the core-v2 project, facilitating local development, testing, and deployment.

## Table of Contents

- [Dockerfiles](#dockerfiles)
  - [core-v2.base.Dockerfile](#core-v2basedockerfile)
  - [core-v2.Dockerfile](#core-v2dockerfile)
  - [testnet.Dockerfile](#testnetdockerfile)
- [Docker Compose Files](#docker-compose-files)
  - [testnet.compose.yaml](#testnetcomposeyaml)

## Dockerfiles

### core-v2.base.Dockerfile

This Dockerfile sets up a lightweight Ubuntu 20.04 environment with necessary tools for Solidity development. It installs dependencies, sets the timezone, and installs Foundry (Forge and Cast). The project directory is prepared and dependencies are initialized using Forge.

**Usage:**
```bash
docker build -t core-v2:base -f dockerfiles/core-v2.base.Dockerfile .
```

### core-v2.Dockerfile

This Dockerfile builds upon the `core-v2:base` image to set up the environment for compiling and running the core-v2 project. It compiles the Solidity contracts and includes all necessary project files for deployment and testing.

**Usage:**
```bash
docker build -t core-v2:latest -f dockerfiles/core-v2.Dockerfile .
```

### testnet.Dockerfile

This Dockerfile extends the `core-v2:latest` image to configure and run a local Anvil testnet node. It sets environment variables, exposes the testnet port, and runs the testnet configuration script to start the node.

**Usage:**
```bash
docker build -t core-v2:testnet -f dockerfiles/testnet.Dockerfile .
```

## Docker Compose Files

### testnet.compose.yaml

This Docker Compose file sets up a local testnet environment for deploying and testing smart contracts using core-v2. It defines two services:
- `node`: Runs a local RPC node for the testnet.
- `deploy-contracts`: Deploys smart contracts to the local testnet node.

**Usage:**
```bash
docker compose -f dockerfiles/testnet.compose.yaml -p testnet-deployment up
```