// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ICredentialCache.sol";


contract CoreV2_2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable CREDENTIALCACHE;
    
    error PolicyOverflows();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _credentialCache_) {
        CREDENTIALCACHE = _credentialCache_;
        _disableInitializers();
    }

    function initialize() reinitializer(2) public {}

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function checkCredential(address entity_, uint32 policyId_) public view returns(bool) {
        return checkCredential(uint256(policyId_), entity_);
    }

    function checkCredential(uint256 policyId_, address entity_) public view returns(bool) {
        if (policyId_ > type(uint32).max) {
            revert PolicyOverflows();
        }
        return ICredentialCache(CREDENTIALCACHE).checkCredential(entity_, uint32(policyId_));
    }
}