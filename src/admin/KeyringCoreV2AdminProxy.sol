// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {KeyringCoreV2Base} from "../base/KeyringCoreV2Base.sol";

/**
 * @title KeyringCoreV2AdminProxy
 * @dev This contract interacts with KeyringCoreV2Base and delegates admin functions to specific roles managed by KeyringAdminV2.
 */
contract KeyringCoreV2AdminProxy {

    // Errors
    error Unauthorized(string reason);
    
    // Events
    event RoleAssigned(string role, address indexed assignedTo);
    event BlacklistManagerAdded(uint256 indexed policyId, address indexed manager);
    event BlacklistManagerRemoved(uint256 indexed policyId, address indexed manager);
    event MasterAdminSet(address indexed newMasterAdmin);

    KeyringCoreV2Base public immutable coreContract;
    
    // Master admin address
    address public masterAdmin;

    // Admin roles
    address public keyManagerAdmin;
    address public feeCollectorAdmin;

    // Blacklist managers
    mapping(uint256 => mapping(address => bool)) public blacklistManagers;

    /**
     * @dev Initializes the contract with the core contract and master admin address.
     * @param _coreContract Address of the core contract.
     * @param _masterAdmin Address of the master admin.
     */
    constructor(address _coreContract, address _masterAdmin) {
        coreContract = KeyringCoreV2Base(_coreContract);
        masterAdmin = _masterAdmin;
        emit MasterAdminSet(_masterAdmin);
    }
    
    /**
     * @notice Set a new master admin.
     * @dev Only callable by the current master admin.
     * @param _admin Address of the new master admin.
     */
    function setMasterAdmin(address _admin) external {
        if (msg.sender != masterAdmin) {
            revert Unauthorized("MAS");
        }
        masterAdmin = _admin;
        emit MasterAdminSet(_admin);
    }

    /**
     * @notice Set the key manager admin.
     * @dev Only callable by the master admin.
     * @param _admin Address of the new key manager admin.
     */
    function setKeyManagerAdmin(address _admin) external {
        if (msg.sender != masterAdmin) {
          revert Unauthorized("MAS");
        }
        keyManagerAdmin = _admin;
        emit RoleAssigned("KeyManagerAdmin", _admin);
    }

    /**
     * @notice Set the fee collector admin.
     * @dev Only callable by the master admin.
     * @param _admin Address of the new fee collector admin.
     */
    function setFeeCollectorAdmin(address _admin) external {
        if (msg.sender != masterAdmin) {
          revert Unauthorized("MAS");
        }
        feeCollectorAdmin = _admin;
        emit RoleAssigned("FeeCollectorAdmin", _admin);
    }

    /**
     * @notice Add a blacklist manager.
     * @dev Only callable by the master admin.
     * @param manager Address of the new blacklist manager.
     */
    function addBlacklistManager(uint256 policyId, address manager) external {
        if (msg.sender != masterAdmin) {
          revert Unauthorized("MAS");
        }
        blacklistManagers[policyId][manager] = true;
        emit BlacklistManagerAdded(policyId, manager);
    }

    /**
     * @notice Remove a blacklist manager.
     * @dev Only callable by the master admin.
     * @param manager Address of the blacklist manager to remove.
     */
    function removeBlacklistManager(uint256 policyId, address manager) external {
        if (msg.sender != masterAdmin) {
          revert Unauthorized("MAS");
        }
        blacklistManagers[policyId][manager] = false;
        emit BlacklistManagerRemoved(policyId, manager);
    }

    /**
     * @notice Set admin on the base core contract.
     * @dev Only callable by the master admin.
     * @param _admin Address of the new admin.
     */
    function setAdminOnBaseContract(address _admin) external {
      if (msg.sender != masterAdmin) {
          revert Unauthorized("MAS");
      }
      coreContract.setAdmin(_admin);
    }

    // Register a new RSA key - only callable by key manager admin
    /**
     * @notice Register a new RSA key.
     * @dev Only callable by the key manager admin.
     * @param validFrom The start time of the key's validity.
     * @param validTo The end time of the key's validity.
     * @param key The RSA key to register.
     */
    function registerKey(uint256 validFrom, uint256 validTo, bytes memory key) external {
        if (msg.sender != keyManagerAdmin) {
            revert Unauthorized("KMN");
        }
        coreContract.registerKey(validFrom, validTo, key);
    }

    // Revoke an RSA key - only callable by key manager admin
    /**
     * @notice Revoke an RSA key.
     * @dev Only callable by the key manager admin.
     * @param keyHash The hash of the key to revoke.
     */
    function revokeKey(bytes32 keyHash) external {
        if (msg.sender != keyManagerAdmin) {
            revert Unauthorized("KMN");
        }
        coreContract.revokeKey(keyHash);
    }

    // Collect fees - only callable by fee collector admin
    /**
     * @notice Collect fees and transfer to the specified address.
     * @dev Only callable by the fee collector admin.
     * @param to The address to transfer collected fees to.
     */
    function collectFees(address to) external {
        if (msg.sender != feeCollectorAdmin) {
            revert Unauthorized("FCA");
        }
        if (to == address(this)) {
            revert Unauthorized("ASC");
        }
        coreContract.collectFees(to);
    }

    // Blacklist an entity - only callable by blacklist managers
    /**
     * @notice Blacklist an entity.
     * @dev Only callable by a blacklist manager.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity to blacklist.
     */
    function blacklistEntity(uint256 policyId, address entity_) external {
        if (!blacklistManagers[policyId][msg.sender]) {
            revert Unauthorized("BLM");
        }
        coreContract.blacklistEntity(policyId, entity_);
    }

    // Unblacklist an entity - only callable by unblacklist manager admin
    /**
     * @notice Unblacklist an entity.
     * @dev Only callable by the unblacklist manager admin.
     * @param policyId The ID of the policy.
     * @param entity_ The address of the entity to unblacklist.
     */
    function unblacklistEntity(uint256 policyId, address entity_) external {
        if (!blacklistManagers[policyId][msg.sender]) {
            revert Unauthorized("UBM");
        }
        coreContract.unblacklistEntity(policyId, entity_);
    }
}