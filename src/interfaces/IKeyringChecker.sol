// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IKeyringChecker {

/**
     * @notice Creates a credential for an entity.
     * @dev This function overrides the base implementation to include RSA signature verification.
     * @param tradingAddress The trading address.
     * @param policyId The policy ID.
     * @param chainId The chainId for which a credential is valid.
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
    )  external payable;

    /// @notice Checks if a credential is valid for an entity.
    /// @param entity_ The address of the entity.
    /// @param policyId_ The ID of the policy.
    /// @return True if the credential is valid, false otherwise.
    function checkCredential(address entity_, uint32 policyId_) external view returns(bool);

    /// @notice Checks if a credential is valid for an entity.
    /// @param policyId_ The ID of the policy.
    /// @param entity_ The address of the entity.
    /// @return True if the credential is valid, false otherwise.
    function checkCredential(uint256 policyId_, address entity_) external view returns(bool);

}