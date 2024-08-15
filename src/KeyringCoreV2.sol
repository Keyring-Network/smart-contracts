// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./lib/RsaVerifyOptimized.sol";
import "./base/KeyringCoreV2Base.sol";

// NOTE: MAKE EXP PER POLICY VARIANT UPPER BOUND OF MORE THAN 1/2 EPOCH HANDLE IN FE
// NOTE: HANDLED BY BACKEND. WHAT ARE THE ELEMENTS THAT ARE PART OF A POLICY - NO NEED TO TRACK IN CHAIN
// NOTE: RSA KEYS PER POLICY ENFORCED BY BACKEND
// NOTE: LIST OF WALLET CHECKERS PER POLICY NOT ABLE TO PERFORM AS BLACKLISTING IS GLOBAL
// NOTE: PER POLICY BACKDOOR MUST BE HANDLED BY BACKEND
// NOTE: ECDSA FOR NON ZK CREDENTIAL

// QUESTION: SHOULD WE INVALIDATE CREDENTIALS FOR A REVOKED KEY
// QUESTION: SHOULD THERE BE A PER POLICY BLACKLIST
// QUESTION: SHOULD WE DO A PER POLICY CREATE2 SYSTEM OR THIS GLOBAL SYSTEM

/**
 * @title KeyringCoreV2 Contract
 * @dev This contract extends KeyringCoreV2Base and includes RSA verification logic.
 */
contract KeyringCoreV2 is KeyringCoreV2Base, RsaVerifyOptimized {
    constructor() KeyringCoreV2Base() {}

    /**
     * @notice Creates a credential for an entity.
     * @dev This function overrides the base implementation to include RSA signature verification.
     * @param tradingAddress The trading address.
     * @param policyId The policy ID.
     * @param createBefore The time after which the credential is no longer valid for creation.
     * @param validUntil The expiration time of the credential.
     * @param cost The cost of the credential.
     * @param key The RSA key.
     * @param signature The signature.
     * @param backdoor The backdoor data.
     */
    function createCredential(
        address tradingAddress,
        uint256 policyId,
        uint256 createBefore,
        uint256 validUntil,
        uint256 cost,
        bytes calldata key,
        bytes calldata signature,
        bytes calldata backdoor
    ) public payable override {
        // Verify the authenticity of the message using RSA signature
        if (!verifyAuthMessage(tradingAddress, policyId, createBefore, validUntil, cost, key, signature, backdoor)) {
            revert ErrInvalidCredential(policyId, tradingAddress, "SIG");
        }
        // Call the base function to create the credential
        super._createCredential(tradingAddress, policyId, createBefore, validUntil, cost, key, backdoor);
    }
}
