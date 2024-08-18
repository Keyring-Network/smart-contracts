// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

abstract contract RsaMessagePacking {

    /// @notice Error for expired credential.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    /// @param reason The reason for the invalid credential.
    error ErrInvalidCredential(uint256 policyId, address entity, string reason);

    /**
     * @dev Packing format of the message to be signed.
     * @param tradingAddress The trading address.
     * @param policyId The policy ID.
     * @param validFrom The time from which a credential is valid.
     * @param validUntil The expiration time of the credential.
     * @param cost The cost of the credential.
     * @param backdoor The backdoor data.
     * @return The encoded message.
     */
    function packAuthMessage(
        address tradingAddress,
        uint256 policyId,
        uint256 validFrom,
        uint256 validUntil,
        uint256 cost,
        bytes calldata backdoor
    ) public pure returns (bytes memory) {
        if ( policyId > type(uint24).max ) {
            revert ErrInvalidCredential(policyId, tradingAddress, "PID");
        }
        if ( validFrom > type(uint32).max ) {
            revert ErrInvalidCredential(policyId, tradingAddress, "CBF");
        }
        if ( validUntil > type(uint32).max ) {
            revert ErrInvalidCredential(policyId, tradingAddress, "BVU");
        }
        if ( cost > type(uint128).max ) {
            revert ErrInvalidCredential(policyId, tradingAddress, "CST");
        }
        return abi.encodePacked(
            tradingAddress,
            uint8(0),
            uint24(policyId),
            uint32(validFrom),
            uint32(validUntil),
            uint160(cost),
            backdoor
        );
    }
}