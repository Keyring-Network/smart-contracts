// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../src/ICredentialCache.sol";
import "../../src/interfaces/ICoreV2Base.sol";



contract CoreV2UpgradeGenericMock is ICoreV2Base, Initializable, OwnableUpgradeable, UUPSUpgradeable {
        
    /// @dev Address of the admin.
    address internal _admin;

    /// @dev Mapping from key hash to key entry.
    mapping(bytes32 => KeyEntry) internal _keys;

    /// @dev Mapping from policy ID and address to entity data.
    mapping(uint256 => mapping(address => EntityData)) internal _entityData;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint64 public immutable VERSION;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(uint64 version_) {
        VERSION = version_;
        _disableInitializers();
    }

    function initialize() reinitializer(VERSION)  public {
        __Ownable_init(owner());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

}