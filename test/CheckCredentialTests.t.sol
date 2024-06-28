// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KeyringCoreV2.sol";

contract CheckCredentialTests is Test {
    KeyringCoreV2 keyring;
    address admin = address(0x1);
    address policyManager = address(0x2);
    address user = address(0x3);
    uint256 policyId = 1;
    uint256 validTo = block.timestamp + 1000;
    KeyringCoreV2.RsaKey rsaKey;

    function setUp() public {
        keyring = new KeyringCoreV2();
        keyring.transferOwnership(admin);
        rsaKey = KeyringCoreV2.RsaKey(bytes("exponent"), bytes("modulus"));
    }

    function testCheckCredentialPolicyActiveNotBlacklisted() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(policyManager);
        keyring.whitelist{value: 1 ether}(policyId, user);
        vm.prank(admin);
        keyring.createCredential(rsaKey, user, uint24(policyId), uint32(validTo), bytes("backdoor"));
        assertTrue(keyring.checkCredential(policyId, user));
    }

    function testCheckCredentialPolicyActiveBlacklisted() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(policyManager);
        keyring.whitelist{value: 1 ether}(policyId, user);
        vm.prank(admin);
        keyring.blacklistEntity(user);
        assertFalse(keyring.checkCredential(policyId, user));
    }

    function testCheckCredentialPolicySuspendedNotBlacklisted() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(policyManager);
        keyring.setPolicyState(policyId, true);
        assertTrue(keyring.checkCredential(policyId, user));
    }

    function testCheckCredentialPolicySuspendedBlacklisted() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(policyManager);
        keyring.setPolicyState(policyId, true);
        vm.prank(admin);
        keyring.blacklistEntity(user);
        assertFalse(keyring.checkCredential(policyId, user));
    }

    function testCheckCredentialConditions() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);

        // Policy Active, Not Blacklisted
        vm.prank(policyManager);
        keyring.whitelist{value: 1 ether}(policyId, user);
        vm.prank(admin);
        keyring.createCredential(rsaKey, user, uint24(policyId), uint32(validTo), bytes("backdoor"));
        assertTrue(keyring.checkCredential(policyId, user));

        vm.prank(policyManager);
        keyring.unwhitelist(policyId, user);
        assertFalse(keyring.checkCredential(policyId, user));

        // Policy Active, Blacklisted
        vm.prank(admin);
        keyring.blacklistEntity(user);
        assertFalse(keyring.checkCredential(policyId, user));

        // Policy Suspended, Not Blacklisted
        vm.prank(admin);
        keyring.unblacklistEntity(user);
        vm.prank(policyManager);
        keyring.setPolicyState(policyId, true);
        assertTrue(keyring.checkCredential(policyId, user));

        // Policy Suspended, Blacklisted
        vm.prank(admin);
        keyring.blacklistEntity(user);
        assertFalse(keyring.checkCredential(policyId, user));
    }
}