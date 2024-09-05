// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./lib/RsaVerifyOptimized.sol";
import "./base/KeyringCoreV2Base.sol";
import {KeyringCoreV2Base} from "./base/KeyringCoreV2Base.sol";

/**
 * @title KeyringCoreV2 Contract
 * @dev This contract extends KeyringCoreV2Base and includes RSA verification logic.
 */
contract CoreV2_3 is Initializable, OwnableUpgradeable, UUPSUpgradeable,  RsaVerifyOptimized, KeyringCoreV2Base {
    

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _credentialCache_) {
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
     * @param validFrom The time from which a credential is valid.
     * @param validUntil The expiration time of the credential.
     * @param cost The cost of the credential.
     * @param key The RSA key.
     * @param signature The signature.
     * @param backdoor The backdoor data.
     */
    function createCredential(
        address tradingAddress,
        uint256 policyId,
        uint256 validFrom,
        uint256 validUntil,
        uint256 cost,
        bytes calldata key,
        bytes calldata signature,
        bytes calldata backdoor
    ) public payable override {
        // Verify the authenticity of the message using RSA signature
        if (!verifyAuthMessage(tradingAddress, policyId, validFrom, validUntil, cost, key, signature, backdoor)) {
            revert ErrInvalidCredential(policyId, tradingAddress, "SIG");
        }
        // Call the base function to create the credential
        super._createCredential(tradingAddress, policyId, validUntil, cost, key, backdoor);
    }
}
