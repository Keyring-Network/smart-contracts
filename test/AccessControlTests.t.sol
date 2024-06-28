// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KeyringCoreV2.sol";

contract AccessControlTests is Test {
    KeyringCoreV2 keyring;
    address admin = address(0x1);
    address policyManager = address(0x2);
    address nonAdmin = address(0x4);
    bytes32 keyHash;
    KeyringCoreV2.RsaKey rsaKey;

    function setUp() public {
        keyring = new KeyringCoreV2();
        keyring.transferOwnership(admin);
        rsaKey = KeyringCoreV2.RsaKey(bytes("exponent"), bytes("modulus"));
        keyHash = keccak256(abi.encodePacked(rsaKey.exponent, rsaKey.modulus));
    }

    function testAdminAccessControl() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2.CallerNotAdmin.selector, nonAdmin));
        keyring.registerKey(validFrom, validTo, rsaKey);
    }

    function testPolicyManagerAccessControl() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2.CallerNotPolicyManager.selector, nonAdmin));
        keyring.whitelist{value: 1 ether}(policyId, user);
    }
}