// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title KeyringCoreV2 Contract
 * @dev This contract manages policy states, credentials, and whitelisting/blacklisting of entities.
 */
abstract contract KeyringCoreV2Base {

    uint256 constant public BASETIME = 1704067200; // 01-01-2024 00:00:00 GMT
    uint256 constant public EPOCHLENGTH = 1 hours;

    /**
     * @notice Represents data associated with an entity.
     * @dev Contains whitelisting status and expiration information.
     * @param PADDING Padding bytes.
     * @param blacklisted Indicates if the entity is blacklisted.
     * @param exp The expiration for the entity's credential.
     */
    struct EntityData {
        bytes23 PADDING; // padding
        bool blacklisted;
        uint64 exp;
    }

    /**
     * @notice Represents a key entry.
     * @dev Contains validity status and the validity period of the key.
     * @param PADDING Padding bytes.
     * @param isValid Indicates if the key is valid.
     * @param validFrom The start time of the key's validity.
     * @param validTo The end time of the key's validity.
     */
    struct KeyEntry {
        bytes15 PADDING; // padding
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

    /// @notice Error for expired credential.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    /// @param reason The reason for the invalid credential.
    error ErrInvalidCredential(uint256 policyId, address entity, string reason);

    /// @notice Error for key not found.
    /// @param keyHash The hash of the key that was not found.
    error ErrKeyNotFound(bytes32 keyHash);

    /// @notice Event emitted when a key is registered.
    /// @param keyHash The hash of the key.
    /// @param validFrom The start time of the key's validity.
    /// @param validTo The end time of the key's validity.
    /// @param publicKey The public key.
    event KeyRegistered(bytes31 indexed keyHash, uint256 indexed validFrom, uint256 indexed validTo, bytes publicKey);

    /// @notice Event emitted when a key is revoked.
    /// @param keyHash The hash of the key.
    event KeyRevoked(bytes31 indexed keyHash);

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

    /// @dev Address of the admin.
    address private _admin;

    /// @dev Mapping from key hash to key entry.
    mapping(bytes32 => KeyEntry) private _keys;

    /// @dev Mapping from policy ID and address to entity data.
    mapping(uint256 => mapping(address => EntityData)) private _entityData;

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        _admin = msg.sender;
    }

    // VIEW FUNCTIONS

    /**
     * @notice Returns the address of the admin.
     * @return The address of the admin.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    function getTimeForEndOfEpoch(uint32 epoch) public view returns (uint256) {
        return epochToExp(epoch);
    }

    function getTimeForStartOfEpoch(uint32 epoch) public view returns (uint256) {
        if (epoch == 0) {
            return BASETIME;
        }
        return epochToExp(epoch-1);
    }

    function getCurrentEpoch() public view returns (uint32) {
        return getEpochForTime(block.timestamp);
    }

    function getEpochForTime(uint256 time) public view returns (uint32) {
        if (time < BASETIME) {
            return 0;
        }
        return uint32((time - BASETIME) / EPOCHLENGTH);
    }

    /**
     * @notice Returns the hash of a key.
     * @param key The key.
     * @return The hash of the key.
     */
    function getKeyHash(bytes memory key) public pure returns (bytes32) {
        return keccak256(key);
    }

    /**
     * @notice Checks if a key exists.
     * @param keyHash The hash of the key.
     * @return True if the key exists, false otherwise.
     */
    function keyExists(bytes32 keyHash) public view returns (bool) {
        return _keys[keyHash].isValid;
    }

    /**
     * @notice Returns the validity start time of a key.
     * @param keyHash The hash of the key.
     * @return The start time of the key's validity.
     */
    function keyValidFrom(bytes32 keyHash) public view returns (uint64) {
        return _keys[keyHash].validFrom;
    }

    /**
     * @notice Returns the validity end time of a key.
     * @param keyHash The hash of the key.
     * @return The end time of the key's validity.
     */
    function keyValidTo(bytes32 keyHash) public view returns (uint64) {
        return _keys[keyHash].validTo;
    }

    /**
     * @notice Returns the details of a key.
     * @param keyHash The hash of the key.
     * @return The KeyEntry struct containing key details.
     */
    function keyDetails(bytes32 keyHash) public view returns (KeyEntry memory) {
        return _keys[keyHash];
    }

    /**
     * @notice Checks if an entity is blacklisted for a specific policy.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity.
     * @return True if the entity is blacklisted, false otherwise.
     */
    function entityBlacklisted(uint256 policyId, address entity_) public view returns (bool) {
        return _entityData[policyId][entity_].blacklisted;
    }

    /**
     * @notice Returns the expiration of an entity for a specific policy.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity.
     * @return The expiration of the entity credential.
     */
    function entityExp(uint256 policyId, address entity_) public view returns (uint64) {
        return _entityData[policyId][entity_].exp;
    }

    /**
     * @notice Returns the data associated with a specific entity.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity.
     * @return The EntityData struct containing blacklisting and expiration information.
     */
    function entityData(uint256 policyId, address entity_) public view returns (EntityData memory) {
        return _entityData[policyId][entity_];
    }

    /**
     * @notice Checks if an entity has a valid credential.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity to check.
     * @return True if the entity has a valid credential, false otherwise.
     */
    function checkCredential(uint256 policyId, address entity_) public view returns (bool) {
        EntityData memory ed = _entityData[policyId][entity_];
        if (!ed.blacklisted && ed.exp > block.timestamp) {
            return true;
        }
        return false;
    }

    // CREDENTIAL CREATION

    /**
     * @notice Creates a credential for an entity.
     * @param tradingAddress The trading address.
     * @param policyId The policy ID.
     * @param epoch The epoch time.
     * @param epochExp The epoch expiration time.
     * @param cost The cost of the credential.
     * @param key The RSA key.
     * @param signature The signature.
     * @param backdoor The backdoor data.
     */
    function createCredential(
        address tradingAddress,
        uint24 policyId,
        uint32 epoch,
        uint32 epochExp,
        uint168 cost,
        bytes calldata key,
        bytes calldata signature,
        bytes calldata backdoor
    ) public virtual payable {
        _createCredential(tradingAddress, policyId, epoch, epochExp, cost, key, backdoor);
    }

    // ADMIN CAPABILITIES

    /**
     * @notice Sets a new admin.
     * @param newAdmin The address of the new admin.
     * @dev Only callable by the current admin.
     */
    function setAdmin(address newAdmin) external {
        if (msg.sender != _admin) {
            revert ErrCallerNotAdmin(msg.sender);
        }
        _admin = newAdmin;
    }

    /**
     * @notice Registers a new RSA key.
     * @param validFrom The start time of the key's validity.
     * @param validTo The end time of the key's validity.
     * @param key The RSA key.
     * @dev Only callable by the admin.
     */
    function registerKey(uint256 validFrom, uint256 validTo, bytes memory key) external {
        if (msg.sender != _admin) {
            revert ErrCallerNotAdmin(msg.sender);
        }
        if (validTo <= validFrom) {
            revert ErrInvalidKeyRegistration("IVP");
        }
        bytes32 keyHash = getKeyHash(key);
        if (_keys[keyHash].isValid) {
            revert ErrInvalidKeyRegistration("KAR");
        }
        _keys[keyHash] = KeyEntry(bytes15(0), true, uint64(validFrom), uint64(validTo));
        emit KeyRegistered(bytes31(keyHash), validFrom, validTo, key);
    }

    /**
     * @notice Revokes an RSA key.
     * @param keyHash The hash of the key to revoke.
     * @dev Only callable by the admin.
     */
    function revokeKey(bytes32 keyHash) external {
        if (msg.sender != _admin) {
            revert ErrCallerNotAdmin(msg.sender);
        }
        if (!_keys[keyHash].isValid) {
            revert ErrKeyNotFound(keyHash);
        }

        _keys[keyHash].isValid = false;
        emit KeyRevoked(bytes31(keyHash));
    }

    /**
     * @notice Blacklists an entity.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity to blacklist.
     * @dev Only callable by the admin.
     */
    function blacklistEntity(uint256 policyId, address entity_) public {
        if (msg.sender != _admin) {
            revert ErrCallerNotAdmin(msg.sender);
        }
        EntityData memory ed = EntityData(bytes23(0), true, 0);
        _entityData[policyId][entity_] = ed;
        emit EntityBlacklisted(policyId, entity_);
    }

    /**
     * @notice Removes an entity from the blacklist.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity to unblacklist.
     * @dev Only callable by the admin.
     */
    function unblacklistEntity(uint256 policyId, address entity_) public {
        if (msg.sender != _admin) {
            revert ErrCallerNotAdmin(msg.sender);
        }
        EntityData memory ed = EntityData(bytes23(0), false, 0);
        _entityData[policyId][entity_] = ed;
        emit EntityUnblacklisted(policyId, entity_);
    }

    /**
    * @notice Collects fees and transfers them to the specified address.
    * @param to The address to transfer the collected fees to.
    * @dev Only callable by the admin.
    * @custom:requires msg.sender must be the admin.
    * @custom:emits This function does not emit any events.
    * @custom:throws ErrCallerNotAdmin if the caller is not the admin.
    */
    function collectFees(address to) public {
        if (msg.sender != _admin) {
            revert ErrCallerNotAdmin(msg.sender);
        }
        payable(to).transfer(address(this).balance);
    }



    // INTERNAL FUNCTIONS

    /**
     * @notice Converts epoch time to expiration time.
     * @param epoch The epoch time.
     * @return The expiration time.
     */
    function epochToExp(uint32 epoch) internal pure returns (uint64) {
        return uint64(BASETIME + EPOCHLENGTH + (epoch * EPOCHLENGTH));
    }

    /**
     * @notice Internal function that creates a credential for an entity.
     * @param tradingAddress The trading address.
     * @param policyId The policy ID.
     * @param epoch The epoch time.
     * @param epochExp The epoch expiration time.
     * @param cost The cost of the credential.
     * @param key The RSA key.
     * @param backdoor The backdoor data.
     */
    function _createCredential(
        address tradingAddress,
        uint24 policyId,
        uint32 epoch,
        uint32 epochExp,
        uint168 cost,
        bytes calldata key,
        bytes calldata backdoor) internal { 
        // Verify the cost of the credential creation matches the value sent.
        if (msg.value != cost) {
            revert ErrInvalidCredential(policyId, tradingAddress, "VAL");
        }
        // Verify the key is valid.
        {
            bytes32 keyHash = getKeyHash(key);
            KeyEntry memory entry = _keys[keyHash];
            uint256 currentTime = block.timestamp;
            bool isValid = (entry.isValid && currentTime >= entry.validFrom && currentTime <= entry.validTo);
            // Verify the key is valid.
            if (!isValid) {
                revert ErrInvalidCredential(policyId, tradingAddress, "BDK");
            }
        }
        // Verify the credential was created within this epoch or the last epoch.
        {
            uint256 thisEpochExp = epochToExp(epoch + 1);
            if (block.timestamp > thisEpochExp) {
                revert ErrInvalidCredential(policyId, tradingAddress, "EPO");
            }
        }
        // Load the entity data.
        EntityData memory ed = _entityData[policyId][tradingAddress];
        // Check if the entity is blacklisted.
        if (ed.blacklisted) {
            revert ErrInvalidCredential(policyId, tradingAddress, "BLK");
        }
        // Calculate the expiration for the credential.
        uint256 exp = epochToExp(epochExp);
        if (exp < block.timestamp) {
            revert ErrInvalidCredential(policyId, tradingAddress, "EXP");
        }
        // Set the expiration for the entity.
        ed.exp = uint64(exp);
        // Update the entity data.
        _entityData[policyId][tradingAddress] = ed;
        // Emit the credential created event.
        emit CredentialCreated(policyId, tradingAddress, exp, backdoor);
    }

}
