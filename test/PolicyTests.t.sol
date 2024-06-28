// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KeyringCoreV2.sol";

contract PolicyTests is Test {
    KeyringCoreV2 keyring;
    address admin = address(0x1);
    address policyManager = address(0x2);
    address nonAdmin = address(0x4);
    uint256 policyId = 1;

    function setUp() public {
        keyring = new KeyringCoreV2();
        keyring.transferOwnership(admin);
    }

    function testInitialPolicyState() public {
        assertFalse(keyring.policyExists(policyId));
    }

    function testPolicyCreation() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        assertTrue(keyring.policyExists(policyId));
        assertEq(keyring.policyManager(policyId), policyManager);
    }

    function testPolicyCreationRevertsIfAlreadyExists() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(admin);
        vm.expectRevert(KeyringCoreV2.PolicyAlreadyExists.selector);
        keyring.createPolicy(policyId, policyManager);
    }

    function testPolicyCreationRevertsIfCalledByNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2.CallerNotAdmin.selector, nonAdmin));
        keyring.createPolicy(policyId, policyManager);
    }

    function testPolicySuspension() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(policyManager);
        keyring.setPolicyState(policyId, true);
        assertTrue(keyring.policySuspended(policyId));
    }

    function testPolicyActivation() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(policyManager);
        keyring.setPolicyState(policyId, true);
        vm.prank(policyManager);
        keyring.setPolicyState(policyId, false);
        assertFalse(keyring.policySuspended(policyId));
    }

    function testPolicyManagerChange() public {
        vm.prank(admin);
        keyring.createPolicy(policyId, policyManager);
        vm.prank(admin);
        keyring.changePolicyManager(policyId, nonAdmin);
        assertEq(keyring.policyManager(policyId), nonAdmin);
    }

    function testPolicyManagerChangeRevertsIfPolicyNotExists() public {
        vm.prank(admin);
        vm.expectRevert(KeyringCoreV2.PolicyDoesNotExist.selector);
        keyring.changePolicyManager(policyId, nonAdmin);
    }
}