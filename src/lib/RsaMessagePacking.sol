// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/ICoreV2Base.sol";

contract RsaMessagePacking is ICoreV2Base {

    /**
     * @dev Packing format of the message to be signed.
     * @param tradingAddress The trading address.
     * @param policyId The policy ID.
     * @param chainId The chainId for which a credential is valid.
     * @param validUntil The expiration time of the credential.
     * @param cost The cost of the credential.
     * @param backdoor The backdoor data.
     * @return The encoded message.
     */
    function packAuthMessage(
        address tradingAddress,
        uint256 policyId,
        uint256 chainId,
        uint256 validUntil,
        uint256 cost,
        bytes calldata backdoor
    ) public view returns (bytes memory) {
        if ( policyId > type(uint24).max ) {
            revert ErrInvalidCredential(policyId, tradingAddress, "PID");
        }
        if ( validUntil > type(uint32).max ) {
            revert ErrInvalidCredential(policyId, tradingAddress, "BVU");
        }
        if ( cost > type(uint128).max ) {
            revert ErrInvalidCredential(policyId, tradingAddress, "CST");
        }
        
        // Check for chainId mismatch
        if (chainId != block.chainid) {
            revert ErrInvalidCredential(policyId, tradingAddress, "CHAINID");
        }
   
        // Check for insufficient cost
        if (cost == 0) {
            revert ErrCostNotSufficient(policyId, tradingAddress, "COST");
        }
        return abi.encodePacked(
            tradingAddress,
            uint8(0),
            uint24(policyId),
            uint32(chainId),
            uint32(validUntil),
            uint160(cost),
            backdoor
        );
    }
}