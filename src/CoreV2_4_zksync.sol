// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./lib/EIP191Verify.sol";
import "./base/KeyringCoreV2Base.sol";
import {KeyringCoreV2Base} from "./base/KeyringCoreV2Base.sol";

/**
 * @title KeyringCoreV2 Contract
 * @dev This contract extends KeyringCoreV2Base and includes RSA verification logic.
 */
contract CoreV2_4_zksync is Initializable, OwnableUpgradeable, UUPSUpgradeable, EIP191Verify, KeyringCoreV2Base {
    

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() onlyOwner reinitializer(3) public {
        KeyringCoreV2Base._initialize();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /**
     * @notice Creates a credential for an entity.
     * @dev This function overrides the base implementation to include RSA signature verification.
     * @param tradingAddress The trading address.
     * @param policyId The policy ID.
     * @param validUntil The expiration time of the credential.
     * @param cost The cost of the credential.
     * @param key The RSA key.
     * @param signature The signature.
     * @param backdoor The backdoor data.
     */
    function createCredential(
        address tradingAddress,
        uint256 policyId,
        uint256 chainId,
        uint256 validUntil,
        uint256 cost,
        bytes calldata key,
        bytes calldata signature,
        bytes calldata backdoor
    ) public payable override {
        // Verify the authenticity of the message using RSA signature
        if (!verifyAuthMessage(tradingAddress, policyId, chainId, validUntil, cost, key, signature, backdoor)) {
            revert ErrInvalidCredential(policyId, tradingAddress, "SIG");
        }
        // NEW LOGIC FOR CHAIN ENFORCEMENT
        if (cost > 0) {
            if (chainId != block.chainid) {
                revert ErrInvalidCredential(policyId, tradingAddress, "CID");
            }
        }
        // Call the base function to create the credential
        super._createCredential(tradingAddress, policyId, validUntil, cost, key, backdoor);
    }
}
