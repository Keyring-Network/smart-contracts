// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title ICoreV2Base
 * @notice Interface for the CoreV2Base contract. This acts as a definition point for structs, events, and errors.
 */
interface ICoreV2Base {

    /**
     * @notice Represents data associated with an entity.
     * @dev Contains whitelisting status and expiration information.
     * @param blacklisted Indicates if the entity is blacklisted.
     * @param exp The expiration for the entity's credential.
     */
    struct EntityData {
        bool blacklisted;
        uint64 exp;
    }

    /**
     * @notice Represents a key entry.
     * @dev Contains validity status and the validity period of the key.
     * @param isValid Indicates if the key is valid.
     * @param validFrom The start time of the key's validity.
     * @param validTo The end time of the key's validity.
     */
    struct KeyEntry {
        bool isValid;
        uint64 validFrom;
        uint64 validTo;
    }

    /// @notice Error for unauthorized admin caller.
    /// @param caller The address of the unauthorized caller.
    error ErrCallerNotAdmin(address caller);

    /// @notice Error for invalid key registration.
    /// @param reason The reason for the invalid key registration.
    error ErrInvalidKeyRegistration(string reason);

    /// @notice Error for key not found.
    /// @param keyHash The hash of the key that was not found.
    error ErrKeyNotFound(bytes32 keyHash);

    /// @notice Error for failed send of value.
    error ErrFailedSendOfValue();

    /// @notice Error for expired credential.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    /// @param reason The reason for the invalid credential.
    error ErrInvalidCredential(uint256 policyId, address entity, string reason);


    /// @notice Event emitted when a key is registered.
    /// @param keyHash The hash of the key.
    /// @param validFrom The start time of the key's validity.
    /// @param validTo The end time of the key's validity.
    /// @param publicKey The public key.
    event KeyRegistered(bytes32 indexed keyHash, uint256 indexed validFrom, uint256 indexed validTo, bytes publicKey);

    /// @notice Event emitted when a key is revoked.
    /// @param keyHash The hash of the key.
    event KeyRevoked(bytes32 indexed keyHash);

    /// @notice Event emitted when a credential is created.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    /// @param exp The expiration for the credential.
    /// @param backdoor The backdoor data.
    event CredentialCreated(uint256 indexed policyId, address indexed entity, uint256 indexed exp, bytes backdoor);

    /// @notice Event emitted when a credential is revoked.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    event CredentialRevoked(uint256 indexed policyId, address indexed entity);

    /// @notice Event emitted when an entity is blacklisted.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    event EntityBlacklisted(uint256 indexed policyId, address indexed entity);

    /// @notice Event emitted when an entity is unblacklisted.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    event EntityUnblacklisted(uint256 indexed policyId, address indexed entity);

    /// @notice Event emitted when the admin is set.
    /// @param oldAdmin The address of the old admin.
    /// @param newAdmin The address of the new admin.
    event AdminSet(address indexed oldAdmin, address indexed newAdmin);

}