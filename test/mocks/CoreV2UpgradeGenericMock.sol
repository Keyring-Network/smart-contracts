// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../src/ICredentialCache.sol";


contract CoreV2UpgradeGenericMock is Initializable, OwnableUpgradeable, UUPSUpgradeable {
        
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