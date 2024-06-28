// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KeyringCoreV2.sol";

contract EntityTests is Test {
    KeyringCoreV2 keyring;
    address admin = address(0x1);
    address policyManager = address(0x2);
    address user = address(0x3);
    uint256 policyId = 1;

    function setUp() public {
        keyring = new KeyringCoreV2();
        keyring.transferOwnership(admin);
    }

    function testInitialEntityState() public {
        (bool whitelisted, uint64 exp) = keyring.entityData(policyId, user);
        assertFalse(whitelisted);
        assertEq(exp, 0);
    }

    function testWhitelisting() public {
        vm.prank(policyManager);
        keyring.whitelist{value: 1 ether}(policyId, user);
        (bool whitelisted,) = keyring.entityData(policyId, user);
        assertTrue(whitelisted);
    }

    function testRemoveWhitelisting() public {
        vm.prank(policyManager);
        keyring.whitelist{value: 1 ether}(policyId, user);
        vm.prank(policyManager);
        keyring.unwhitelist(policyId, user);
        (bool whitelisted,) = keyring.entityData(policyId, user);
        assertFalse(whitelisted);
    }

    function testCredentialExpiration() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(policyManager);
        keyring.whitelist{value: 1 ether}(policyId, user);
        vm.prank(admin);
        keyring.createCredential(rsaKey, user, uint24(policyId), uint32(validTo), bytes("backdoor"));
        (bool whitelisted, uint64 exp) = keyring.entityData(policyId, user);
        assertEq(exp, validTo);
    }
}