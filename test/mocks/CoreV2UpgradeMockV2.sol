// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../../src/ICredentialCache.sol";


contract CoreV2UpgradeMockV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    bytes32 public constant TEST = keccak256("TEST");
    address public constant CREDENTIALCACHE = address(1);
    
    error PolicyOverflows();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() reinitializer(3)  public {
        __Ownable_init(owner());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function checkCredential(uint256, address) public pure returns(bool) {
        return true;
    }
}