### Project Documentation

#### Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Smart Contracts](#smart-contracts)
4. [Scripts](#scripts)
5. [Utilities](#utilities)
6. [Tests](#tests)
7. [Dockerfiles](#dockerfiles)
8. [Usage Information](#usage-information)
9. [Environment Setup](#environment-setup)

---

### Introduction

This project contains the implementation of Keyring Contracts: Version 2.0, a robust system for managing policy states, credentials, and entity whitelisting/blacklisting on the Ethereum blockchain. The project is built using Foundry and includes comprehensive testing, deployment, and local development environments.

---

### Project Structure

The repository is organized into the following directories and files:

- **README.md**: Provides an overview and quickstart guide for the project.
- **.gitignore**: Specifies files and directories to be ignored by git.
- **.gitmodules**: Contains git submodule configurations.
- **genesis.json**: The genesis file for the local testnet.
- **foundry.toml**: Configuration file for Foundry.
- **dockerfiles/**: Contains Dockerfiles and Docker Compose configurations.
- **bin/**: Includes various shell scripts for building, deploying, and testing the project.
- **utils/**: Utility scripts for generating test vectors.
- **test/**: Solidity test files.
- **script/**: Deployment and configuration scripts.
- **src/**: Solidity smart contract source files.

---

### Smart Contracts

#### KeyringCoreV2.sol

- **Purpose**: Manages policy states, credentials, and whitelisting/blacklisting of entities.
- **Features**:
  - Credential creation with RSA signature verification.
  - Key registration and revocation.
  - Entity blacklisting and unblacklisting.
  - Fee collection by admin.

#### KeyringCoreV2Base.sol

- **Purpose**: Provides base functionalities for the KeyringCoreV2 contract.
- **Features**:
  - Admin management.
  - Key entry and entity data structures.
  - Event emissions for key and credential activities.

#### KeyringCoreV2Unsafe.sol

- **Purpose**: Unsafe version of KeyringCoreV2 for testing purposes only.

---

### Scripts

#### unsafe.s.sol

- **Purpose**: Script for deploying the `KeyringCoreV2Unsafe` contract.
- **Usage**:
  ```sh
  forge script script/unsafe.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY>
  ```

---

### Utilities

#### generateTestVectorRSA.py

- **Purpose**: Python script to generate test vectors for RSA-based signatures.
- **Features**:
  - RSA key generation.
  - Message encoding and signing.
  - Signature verification.

---

### Tests

#### RsaVerifyOptimizedTest.t.sol

- **Purpose**: Tests the RSA verification logic.
- **Features**:
  - Verify RSA signatures.
  - Measure gas usage for verification.

#### KeyringCoreV2BaseTest.t.sol

- **Purpose**: Comprehensive tests for the KeyringCoreV2Base contract.
- **Features**:
  - Admin functionality tests.
  - Key registration and revocation.
  - Credential creation and validation.
  - Entity blacklisting and unblacklisting.

---

### Dockerfiles

#### core-v2.base.Dockerfile

- **Purpose**: Sets up a lightweight Ubuntu environment for Solidity development.
- **Usage**:
  ```sh
  docker build -t core-v2:base -f dockerfiles/core-v2.base.Dockerfile .
  ```

#### core-v2.Dockerfile

- **Purpose**: Builds upon the base image to set up the environment for compiling and running the project.
- **Usage**:
  ```sh
  docker build -t core-v2:latest -f dockerfiles/core-v2.Dockerfile .
  ```

#### testnet.Dockerfile

- **Purpose**: Configures and runs a local Anvil testnet node.
- **Usage**:
  ```sh
  docker build -t core-v2:testnet -f dockerfiles/testnet.Dockerfile .
  ```

#### testnet.compose.yaml

- **Purpose**: Sets up a local testnet environment using Docker Compose.
- **Usage**:
  ```sh
  docker-compose -f dockerfiles/testnet.compose.yaml up
  ```

---

### Usage Information

#### Quickstart

1. **Build Docker Images**:
   ```sh
   bash bin/develop.sh
   ```

2. **Start a Local Testnet in Docker**:
   ```sh
   bash bin/testnet.sh
   ```

3. **Run Solidity Tests in Docker**:
   ```sh
   bash bin/tests.sh
   ```

#### Local Development

1. **Build Contracts**:
   ```sh
   forge build
   ```

2. **Run Tests**:
   ```sh
   forge test
   ```

3. **Gas Snapshots**:
   ```sh
   forge snapshot
   ```

4. **Deploy Contracts**:
   ```sh
   forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
   ```

---

### Environment Setup

1. **Install Dependencies**:
   - Docker
   - jq (for `testnet-config.sh`)

2. **Clone the Repository**:
   ```sh
   git clone <repository_url>
   cd <repository_directory>
   ```

3. **Initialize Submodules**:
   ```sh
   git submodule update --init --recursive
   ```

4. **Install Foundry**:
   ```sh
   curl -L https://foundry.paradigm.xyz | bash
   ~/.foundry/bin/foundryup
   ```

5. **Build Docker Images**:
   ```sh
   bash bin/develop.sh
   ```

6. **Start Local Testnet**:
   ```sh
   bash bin/testnet.sh
   ```

---

For detailed descriptions and usage of the scripts, please refer to the respective README.md files in the `bin/` and `dockerfiles/` directories. For additional documentation, visit the [Foundry Documentation](https://book.getfoundry.sh/).