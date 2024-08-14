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

contract KeyringCoreV2 is KeyringCoreV2Base, RsaVerifyOptimized {
    constructor() KeyringCoreV2Base() {}

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
        if (!verifyAuthMessage(tradingAddress, policyId, createBefore, validUntil, cost, key, signature, backdoor)) {
            revert ErrInvalidCredential(policyId, tradingAddress, "SIG");
        }
        super._createCredential(tradingAddress, policyId, createBefore, validUntil, cost, key, backdoor);
    }
}