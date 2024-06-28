// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./rsaverify.sol";

// NOTE: MAKE EXP PER POLICY VARIANT UPPER BOUND OF MORE THAN 1/2 EPOCH HANDLE IN FE
// NOTE: HANDLED BY BACKEND. WHAT ARE THE ELEMENTS THAT ARE PART OF A POLICY - NO NEED TO TRACK IN CHAIN
// NOTE: RSA KEYS PER POLICY ENFORCED BY BACKEND
// NOTE: LIST OF WALLET CHECKERS PER POLICY NOT ABLE TO PERFORM AS BLACKLISTING IS GLOBAL
// NOTE: PER POLICY BACKDOOR MUST BE HANDLED BY BACKEND
// NOTE: ECDSA FOR NON ZK CREDENTIAL

// NOTE TODO: MOVE CREDENTIAL COST INTO THE AUTH MESSAGE

// QUESTION: SHOULD WE INVALIDATE CREDENTIALS FOR A REVOKED KEY
// QUESTION: SHOULD THERE BE A PER POLICY BLACKLIST
// QUESTION: SHOULD WE DO A PER POLICY CREATE2 SYSTEM OR THIS GLOBAL SYSTEM

/**
 * @title KeyringCoreV2 Contract
 * @dev This contract manages policy states, credentials, and whitelisting/blacklisting of entities.
 */
contract KeyringCoreV2 is RsaVerifyOptimized {

    /**
     * @notice Represents data associated with an entity.
     * @dev Contains whitelisting status and expiration information.
     * @param _ Padding bytes.
     * @param whitelisted Indicates if the entity is whitelisted.
     * @param exp The expiration for the entity's credential.
     */
    struct EntityData {
        bytes23 PADDING; // padding
        bool whitelisted;
        uint64 exp;
    }

    /**
     * @notice Represents a key entry.
     * @dev Contains validity status and the validity period of the key.
     * @param _ Padding bytes.
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

    /**
     * @notice Represents data associated with a policy.
     * @dev Contains policy manager address, policy suspension state, and policy existence state.
     * @param manager The address of the policy manager.
     * @param suspended Indicates if the policy is suspended.
     * @param exists Indicates if the policy exists.
     */
    struct PolicyData {
        bytes10 PADDING; // padding
        bool exists;
        bool suspended;
        address manager;
    }

    /// @notice Error for invalid key registration.
    /// @param reason The reason for the invalid key registration.
    error InvalidKeyRegistration(string reason);

    /// @notice Error for unauthorized admin caller.
    /// @param caller The address of the unauthorized caller.
    error CallerNotAdmin(address caller);

    /// @notice Error for unauthorized policy manager caller.
    /// @param caller The address of the unauthorized caller.
    error CallerNotPolicyManager(address caller);

    /// @notice Error for incorrect whitelist value.
    /// @param sent The value sent.
    /// @param required The required value.
    error IncorrectWhitelistValue(uint256 sent, uint256 required);

    /// @notice Error for incorrect credential creation value.
    /// @param policyId The ID of the policy.
    /// @param sent The value sent.
    /// @param required The required value.
    error IncorrectCredentialCreationValue(uint256 policyId, uint256 sent, uint256 required);

    /// @notice Error for invalid signature.
    error InvalidSignature();

    /// @notice Error for invalid key.
    error InvalidKey();

    /// @notice Error for key not found.
    error KeyNotFound();

    /// @notice Error for policy already exists.
    error PolicyAlreadyExists();

    /// @notice Error for policy does not exist.
    error PolicyDoesNotExist();

    /// @notice Event emitted when a key is registered.
    /// @param keyHash The hash of the key.
    /// @param validFrom The start time of the key's validity.
    /// @param validTo The end time of the key's validity.
    /// @param publicKey The public key.
    event KeyRegistered(bytes31 indexed keyHash, uint256 indexed validFrom, uint256 indexed validTo, bytes publicKey);

    /// @notice Event emitted when a key is revoked.
    /// @param keyHash The hash of the key.
    event KeyRevoked(bytes31 indexed keyHash);

    /// @notice Event emitted when a policy state is set.
    /// @param policyId The ID of the policy.
    /// @param state The new state of the policy.
    event PolicyStateSet(uint256 indexed policyId, bool indexed state);

    /// @notice Event emitted when a credential is created.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    /// @param exp The expiration for the credential.
    event CredentialCreated(uint256 indexed policyId, address indexed entity, uint256 indexed exp, bytes backdoor);

    /// @notice Event emitted when a credential is revoked.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    event CredentialRevoked(uint256 indexed policyId, address indexed entity);

    /// @notice Event emitted when an address is whitelisted.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    event AddressWhitelisted(uint256 indexed policyId, address indexed entity);

    /// @notice Event emitted when an address is removed from the whitelist.
    /// @param policyId The ID of the policy.
    /// @param entity The address of the entity.
    event AddressUnwhitelisted(uint256 indexed policyId, address indexed entity);

    /// @notice Event emitted when a policy manager is changed.
    /// @param policyId The ID of the policy.
    /// @param newManager The address of the new policy manager.
    event ChangePolicyManager(uint256 indexed policyId, address indexed newManager);

    /// @notice Event emitted when the credential cost is set.
    /// @param policyId The ID of the policy.
    /// @param cost The new credential cost in wei.
    event CredentialCostSet(uint256 indexed policyId, uint256 indexed cost);

    /// @notice Event emitted when an entity is blacklisted.
    /// @param entity The address of the entity.
    event EntityBlacklisted(address indexed entity);

    /// @notice Event emitted when an entity is unblacklisted.
    /// @param entity The address of the entity.
    event EntityUnblacklisted(address indexed entity);

    /// @notice Event emitted when a policy is created.
    /// @param policyId The ID of the policy.
    /// @param manager The address of the policy manager.
    event PolicyCreated(uint256 indexed policyId, address indexed manager);

    /// @dev Address of the admin.
    address private _admin;

    /// @dev Mapping from key hash to key entry.
    mapping(bytes32 => KeyEntry) private _keys;

    /// @dev Mapping from address to blacklist state.
    mapping(address => bool) private _entity_blacklist;

    /// @dev Mapping from policy ID to policy data.
    mapping(uint256 => PolicyData) private _policy_data;

    // WILL BE REMOVED
    /// @dev Mapping from policy ID to credential cost.
    mapping(uint256 => uint256) private _credential_cost;

    /// @dev Mapping from policy ID and address to entity data.
    mapping(uint256 => mapping(address => EntityData)) private _entityData;

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor() {
        _admin = msg.sender;
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
     * @notice Checks if an entity is blacklisted.
     * @param entity_ The address of the entity.
     * @return True if the entity is blacklisted, false otherwise.
     */
    function entityBlacklisted(address entity_) public view returns (bool) {
        return _entity_blacklist[entity_];
    }

    /**
     * @notice Checks if an entity is whitelisted for a specific policy.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity.
     * @return True if the entity is whitelisted, false otherwise.
     */
    function entityWhitelisted(uint256 policyId, address entity_) public view returns (bool) {
        return _entityData[policyId][entity_].whitelisted;
    }

    /**
     * @notice Returns the EXP of an entity for a specific policy.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity.
     * @return The expiration of the entity credential.
     */
    function entityEXP(uint256 policyId, address entity_) public view returns (uint64) {
        return _entityData[policyId][entity_].exp;
    }

    /**
     * @notice Returns the data associated with a specific entity.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity.
     * @return The EntityData struct containing whitelisting and EXP information.
     */
    function entityData(uint256 policyId, address entity_) public view returns (EntityData memory) {
        return _entityData[policyId][entity_];
    }

    /**
     * @notice Checks if a policy exists.
     * @param policyId The ID of the policy.
     * @return True if the policy exists, false otherwise.
     */
    function policyExists(uint256 policyId) public view returns (bool) {
        return _policy_data[policyId].exists;
    }

    /**
     * @notice Returns the address of the current policy manager.
     * @param policyId The ID of the policy.
     * @return The address of the policy manager.
     */
    function policyManager(uint256 policyId) public view returns (address) {
        return _policy_data[policyId].manager;
    }

    /**
     * @notice Returns whether the policy is suspended.
     * @param policyId The ID of the policy.
     * @return True if the policy is suspended, false otherwise.
     */
    function policySuspended(uint256 policyId) public view returns (bool) {
        return _policy_data[policyId].suspended;
    }

    /**
     * @notice Returns the data associated with a specific policy.
     * @param policyId The ID of the policy.
     * @return The PolicyData struct containing policy information.
     */
    function policyData(uint256 policyId) public view returns (PolicyData memory) {
        return _policy_data[policyId];
    }

    /**
     * @notice Returns the cost for creating a credential.
     * @param policyId The ID of the policy.
     * @return The credential cost in wei.
     */
    function credentialCost(uint256 policyId) public view returns (uint256) {
        return _credential_cost[policyId];
    }

    /**
     * @notice Checks if an entity has a valid credential.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity to check.
     * @return True if the entity has a valid credential, false otherwise.
     */
    function checkCredential(uint256 policyId, address entity_) public view returns (bool) {
        if (_entity_blacklist[entity_]) {
            return false;
        }
        if (policySuspended(policyId)) {
            return true;
        }
        EntityData memory ed = _entityData[policyId][entity_];
        if (ed.whitelisted || ed.exp > block.timestamp) {
            return true;
        }
        return false;
    }

    // CREDENTIAL CREATION

    /**
     * @notice Creates a credential for an entity.
     * @param signature The signature.
     * @param key The RSA key.
     * @param tradingAddress The trading address.
     * @param policyId The policy ID.
     * @param epoch The epoch time.
     * @param backdoor The backdoor data.
     */
    function createCredential(
        bytes memory signature,
        RsaKey memory key,
        address tradingAddress,
        uint24 policyId,
        uint32 epoch,
        bytes memory backdoor
    ) public virtual payable {
        if (!verifyAuthMessage(signature, key, tradingAddress, policyId, epoch, backdoor)) {
            revert InvalidSignature();
        }
        uint256 cost = _credential_cost[policyId];
        _createCredential(key, tradingAddress, policyId, epoch, backdoor, cost);
    }
        
function createCredential(
        RsaKey memory key,
        address tradingAddress,
        uint24 policyId,
        uint32 epoch,
        bytes memory backdoor,
        uint256 cost ) internal { 
        bytes32 keyHash = getKeyHash(key);
        if (msg.value != cost) {
            revert IncorrectCredentialCreationValue(policyId, msg.value, cost);
        }
        if (!isKeyValid(keyHash)) {
            revert InvalidKey();
        }
        EntityData memory ed = _entityData[policyId][tradingAddress];
        uint256 exp = epochToEXP(epoch);
        ed.exp = uint64(exp);
        _entityData[policyId][tradingAddress] = ed;
        emit CredentialCreated(policyId, tradingAddress, exp, backdoor);
    }

    // POLICY MANAGER CAPABILITIES

    /**
     * @notice Sets the state of the policy.
     * @param policyId The ID of the policy.
     * @param state The new state of the policy (true for active, false for suspended).
     * @dev Only callable by the policy manager.
     */
    function setPolicyState(uint256 policyId, bool state) public {
        if (msg.sender != policyManager(policyId)) {
            revert CallerNotPolicyManager(msg.sender);
        }
        _policy_data[policyId].suspended = state;
        emit PolicyStateSet(policyId, state);
    }

    /**
     * @notice Whitelists an address.
     * @param policyId The ID of the policy.
     * @param entity_ The address to whitelist.
     * @dev Only callable by the policy manager.
     */
    function whitelist(uint256 policyId, address entity_) public payable {
        if (msg.sender != policyManager(policyId)) {
            revert CallerNotPolicyManager(msg.sender);
        }
        EntityData memory ed = _entityData[policyId][entity_];
        ed.whitelisted = true;
        _entityData[policyId][entity_] = ed;
        emit AddressWhitelisted(policyId, entity_);
    }

    /**
     * @notice Removes an address from the whitelist.
     * @param policyId The ID of the policy.
     * @param entity_ The address to remove from the whitelist.
     * @dev Only callable by the policy manager.
     */
    function unwhitelist(uint256 policyId, address entity_) public {
        if (msg.sender != policyManager(policyId)) {
            revert CallerNotPolicyManager(msg.sender);
        }
        EntityData memory ed = _entityData[policyId][entity_];
        ed.whitelisted = false;
        _entityData[policyId][entity_] = ed;
        emit AddressUnwhitelisted(policyId, entity_);
    }

    // ADMIN CAPABILITIES

    /**
     * @notice Registers a new RSA key.
     * @param validFrom The start time of the key's validity.
     * @param validTo The end time of the key's validity.
     * @param keydata The RSA key data.
     * @dev Only callable by the admin.
     */
    function registerKey(uint256 validFrom, uint256 validTo, RsaKey memory keydata) external {
        if (msg.sender != _admin) {
            revert CallerNotAdmin(msg.sender);
        }
        if (validTo > validFrom) {
            revert InvalidKeyRegistration("Invalid validity period");
        }
        bytes32 keyHash = keccak256(abi.encodePacked(keydata.exponent, keydata.modulus));
        if (_keys[keyHash].isValid) {
            revert InvalidKeyRegistration("Key already registered");
        }

        _keys[keyHash] = KeyEntry(bytes15(0), true, uint64(validFrom), uint64(validTo));
        emit KeyRegistered(bytes31(keyHash), validFrom, validTo, abi.encodePacked(keydata.exponent, keydata.modulus));
    }

    /**
     * @notice Revokes an RSA key.
     * @param keyhash The hash of the key to revoke.
     * @dev Only callable by the admin.
     */
    function revokeKey(bytes32 keyhash) external {
        if (msg.sender != _admin) {
            revert CallerNotAdmin(msg.sender);
        }
        if (!_keys[keyhash].isValid) {
            revert KeyNotFound();
        }

        _keys[keyhash].isValid = false;
        emit KeyRevoked(bytes31(keyhash));
    }

    /**
     * @notice Creates a policy.
     * @param policyId The ID of the policy.
     * @param manager The address of the policy manager.
     * @dev Only callable by the admin.
     */
    function createPolicy(uint256 policyId, address manager) public {
        if (msg.sender != _admin) {
            revert CallerNotAdmin(msg.sender);
        }
        if (_policy_data[policyId].exists) {
            revert PolicyAlreadyExists();
        }
        if (manager == address(0)) {
            manager = _admin;
        }
        PolicyData memory pol;
        pol.manager = manager;
        pol.exists = true;
        pol.suspended = false;
        _policy_data[policyId] = pol;
        emit PolicyCreated(policyId, manager);
    }

    /**
     * @notice Changes the policy manager to a new address.
     * @param policyId The ID of the policy.
     * @param newManager The address of the new policy manager.
     * @dev Only callable by the admin.
     */
    function changePolicyManager(uint256 policyId, address newManager) public {
        if (msg.sender != _admin) {
            revert CallerNotAdmin(msg.sender);
        }
        if (!_policy_data[policyId].exists) {
            revert PolicyDoesNotExist();
        }
        _policy_data[policyId].manager = newManager;
        emit ChangePolicyManager(policyId, newManager);
    }

    /**
     * @notice Sets the cost for creating a credential.
     * @param policyId The ID of the policy.
     * @param cost The new credential cost in wei.
     * @dev Only callable by the admin.
     */
    function setCredentialCost(uint256 policyId, uint256 cost) public {
        if (msg.sender != _admin) {
            revert CallerNotAdmin(msg.sender);
        }
        _credential_cost[policyId] = cost;
        emit CredentialCostSet(policyId, cost);
    }

    /**
     * @notice Blacklists an entity.
     * @param entity_ The address of the entity to blacklist.
     * @dev Only callable by the admin.
     */
    function blacklistEntity(address entity_) public {
        if (msg.sender != _admin) {
            revert CallerNotAdmin(msg.sender);
        }
        _entity_blacklist[entity_] = true;
        emit EntityBlacklisted(entity_);
    }

    /**
     * @notice Removes an entity from the blacklist.
     * @param entity_ The address of the entity to unblacklist.
     * @dev Only callable by the admin.
     */
    function unblacklistEntity(address entity_) public {
        if (msg.sender != _admin) {
            revert CallerNotAdmin(msg.sender);
        }
        _entity_blacklist[entity_] = false;
        emit EntityUnblacklisted(entity_);
    }

    // CRYPTO LOGIC / INTERNAL FUNCTIONS

    /**
     * @notice Converts epoch time to EXP.
     * @param epoch The epoch time.
     * @return The EXP value.
     */
    function epochToEXP(uint32 epoch) internal pure returns (uint64) {
        return 0; //TODO
    }

    /**
     * @notice Checks if a key is valid.
     * @param keyHash The hash of the key.
     * @return True if the key is valid, false otherwise.
     */
    function isKeyValid(bytes32 keyHash) internal view returns (bool) {
        KeyEntry memory entry = _keys[keyHash];
        if (!entry.isValid) {
            return false;
        }
        uint256 currentTime = block.timestamp;
        return currentTime >= entry.validFrom && currentTime <= entry.validTo;
    }

    /**
     * @notice Returns the hash of an RSA key.
     * @param key The RSA key.
     * @return The hash of the key.
     */
    function getKeyHash(bytes memory key) internal pure returns (bytes32) {
        bytes memory packed = abi.encodePacked(key.exponent, key.modulus);
        return keccak256(packed);
    }

}

contract KeyringCoreV2TestRig is KeyringCoreV2 {
    constructor() KeyringCoreV2() {}

    function createCredential(
        RsaKey memory key,
        address tradingAddress,
        uint24 policyId,
        uint32 epoch,
        bytes memory backdoor,
        uint256 cost
    ) public payable overrides {
        super._createCredential(key, tradingAddress, policyId, epoch, backdoor, cost);
    }
