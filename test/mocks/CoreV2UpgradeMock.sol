// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../src/ICredentialCache.sol";


contract CoreV2UpgradeMock is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    bytes32 public constant TEST = keccak256("TEST");
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable CREDENTIALCACHE;
    
    error PolicyOverflows();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _credentialCache_) {
        CREDENTIALCACHE = _credentialCache_;
        _disableInitializers();
    }

    function initialize() reinitializer(2)  public {
        __Ownable_init(owner());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function checkCredential(uint256 policyId_, address entity_) public view returns(bool) {
        if (policyId_ > type(uint32).max) {
            revert PolicyOverflows();
        }
        return ICredentialCache(CREDENTIALCACHE).checkCredential(entity_, uint32(policyId_));
    }
}