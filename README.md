# Keyring Network Smart Contracts

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.22

## Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd smart-contracts
```

2. Install dependencies:

```bash
forge soldeer install
```

## Testing

Run all tests:

```bash
forge test
```

Run tests with verbosity:

```bash
forge test -vv
```

Run specific test file:

```bash
forge test --match-path test/src/KeyringCore.t.sol
```

### Coverage

Generate coverage report:

```bash
forge coverage
```

## Deployment

1. Set up environment variables:

```bash
export PRIVATE_KEY=<your-private-key>
export SIGNATURE_CHECKER_NAME=<checker-name>  # e.g., "AlwaysValidSignatureChecker"
export PROXY_ADDRESS=<proxy-address>  # Optional, for upgrades
export REFERENCE_CONTRACT=<contract-name>  # e.g., "KeyringCoreReferenceContract.sol"
```

2. Deploy using the deployment script:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url <your-rpc-url> --broadcast
```

3. For upgrades, specify the proxy address:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url <your-rpc-url> --broadcast --proxy-address <existing-proxy-address>
```

## Available Signature Checkers

- `AlwaysValidSignatureChecker`: Accepts all signatures except "dead"
- `EIP191SignatureChecker`: Validates EIP-191 signatures
- `RSASignatureChecker`: Validates RSA signatures
