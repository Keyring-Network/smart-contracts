// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDeployOptions {
    struct DeployOptions {
        uint256 deployerPrivateKey;
        string signatureCheckerName;
        string proxyAddress;
        string referenceContract;
    }
}
