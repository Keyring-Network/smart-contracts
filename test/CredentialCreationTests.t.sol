// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KeyringCoreV2.sol";

contract CredentialCreationTests is Test {
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

    function testCredentialCreation() public {
        uint256 cost = 1 ether;
        vm.prank(admin);
        keyring.setCredentialCost(policyId, cost);
        vm.prank(policyManager);
        keyring.whitelist{value: cost}(policyId, user);
        vm.prank(admin);
        keyring.createCredential{value: cost}(rsaKey, user, uint24(policyId), uint32(validTo), bytes("backdoor"));
        (bool whitelisted, uint64 exp) = keyring.entityData(policyId, user);
        assertEq(exp, validTo);
    }

    function testCredentialCreationRevertsWithInvalidSignature() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(policyManager);
        keyring.whitelist{value: 1 ether}(policyId, user);
        vm.prank(admin);
        vm.expectRevert(KeyringCoreV2.InvalidSignature.selector);
        keyring.createCredential(bytes("invalid signature"), rsaKey, user, uint24(policyId), uint32(validTo), bytes("backdoor"));
    }

    function testCredentialCreationRevertsWithInvalidKey() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(policyManager);
        keyring.whitelist{value: 1 ether}(policyId, user);
        vm.prank(admin);
        vm.expectRevert(KeyringCoreV2.InvalidKey.selector);
        keyring.createCredential(bytes("signature"), KeyringCoreV2.RsaKey(bytes("invalid"), bytes("key")), user, uint24(policyId), uint32(validTo), bytes("backdoor"));
    }

    function testCredentialCreationRevertsIfSentValueNotMatchingCost() public {
        uint256 cost = 1 ether;
        vm.prank(admin);
        keyring.setCredentialCost(policyId, cost);
        vm.prank(policyManager);
        keyring.whitelist{value: cost}(policyId, user);
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2.IncorrectCredentialCreationValue.selector, policyId, 0, cost));
        keyring.createCredential{value: 0}(rsaKey, user, uint24(policyId), uint32(validTo), bytes("backdoor"));
    }
}