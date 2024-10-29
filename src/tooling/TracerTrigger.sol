// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface Keyring {
    function checkCredential(uint256 policyId, address entity_) external view returns (bool);
}

contract TracerTrigger {

    event CheckCredential(uint256 indexed policyId, address indexed entity, bool indexed result);
    
    address public immutable KEYRING;

    constructor(address keyring_) {
        KEYRING = keyring_;
    }

    function trigger(uint256 policyId, address entity) public {
        Keyring k = Keyring(KEYRING);
        bool result = k.checkCredential(policyId, entity);
        emit CheckCredential(policyId, entity, result);
    }
}
