// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDeployOptions {
    struct DeployOptions {
        uint256 deployerPrivateKey;
        string signatureCheckerName;
        string proxyAddress;
        string etherscanApiKey;
        string verifierUrl;
    }
}
