## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### Using the Dockerfile

This section provides instructions on how to build, run, use, and stop the Docker container configured to start Anvil, compile your contracts, and deploy them.


#### Building the Docker Image

1. Navigate to your project directory where the Dockerfile is located.

2. Build the Docker image:
   ```sh
   docker build -t forge-anvil .
   ```

#### Running the Docker Container

To start the Docker container and deploy your contracts:

```sh
docker run -p 8545:8545 forge-anvil
```

This command will:

- Start Anvil on port 8545.
- Compile the contracts.
- Deploy the contracts to the Anvil testnet.

#### Stopping the Docker Container

To stop the Docker container:

1. List the running Docker containers to get the container ID or name:
   ```sh
   docker ps
   ```

2. Stop the container using the container ID or name:
   ```sh
   docker stop <container_id_or_name>
   ```

Example:
```sh
docker stop forge-anvil-container
```