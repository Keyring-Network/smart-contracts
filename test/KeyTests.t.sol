// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KeyringCoreV2.sol";

contract KeyTests is Test {
    KeyringCoreV2 keyring;
    address admin = address(0x1);
    uint256 validFrom = block.timestamp;
    uint256 validTo = block.timestamp + 1000;
    bytes32 keyHash;
    KeyringCoreV2.RsaKey rsaKey;

    function setUp() public {
        keyring = new KeyringCoreV2();
        keyring.transferOwnership(admin);
        rsaKey = KeyringCoreV2.RsaKey(bytes("exponent"), bytes("modulus"));
        keyHash = keccak256(abi.encodePacked(rsaKey.exponent, rsaKey.modulus));
    }

    function testInitialKeyState() public {
        assertFalse(keyring.keyExists(keyHash));
    }

    function testKeyRegistration() public {
        vm.prank(admin);
        keyring.registerKey(validFrom, validTo, rsaKey);
        assertTrue(keyring.keyExists(keyHash));
        assertEq(keyring.keyValidFrom(keyHash), validFrom);
        assertEq(keyring.keyValidTo(keyHash), validTo);
    }

    function testKeyInvalidAfterValidTo() public {
        vm.prank(admin);
        keyring.registerKey(validFrom, validTo, rsaKey);
        vm.warp(validTo + 1);
        assertFalse(keyring.isKeyValid(keyHash));
    }

    function testKeyCannotBeRegisteredWithInvalidPeriod() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2.InvalidKeyRegistration.selector, "Invalid validity period"));
        keyring.registerKey(validTo, validFrom, rsaKey);
    }

    function testKeyCannotBeRegisteredIfAlreadyExists() public {
        vm.prank(admin);
        keyring.registerKey(validFrom, validTo, rsaKey);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2.InvalidKeyRegistration.selector, "Key already registered"));
        keyring.registerKey(validFrom, validTo, rsaKey);
    }

    function testKeyRevocation() public {
        vm.prank(admin);
        keyring.registerKey(validFrom, validTo, rsaKey);
        vm.prank(admin);
        keyring.revokeKey(keyHash);
        assertFalse(keyring.isKeyValid(keyHash));
    }

    function testRevokingNonExistentKeyReverts() public {
        vm.prank(admin);
        vm.expectRevert(KeyringCoreV2.KeyNotFound.selector);
        keyring.revokeKey(keyHash);
    }
}