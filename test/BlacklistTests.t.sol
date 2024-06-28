// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KeyringCoreV2.sol";

contract BlacklistTests is Test {
    KeyringCoreV2 keyring;
    address admin = address(0x1);
    address user = address(0x3);

    function setUp() public {
        keyring = new KeyringCoreV2();
        keyring.transferOwnership(admin);
    }

    function testInitialBlacklistState() public {
        assertFalse(keyring.entityBlacklisted(user));
    }

    function testBlacklisting() public {
        vm.prank(admin);
        keyring.blacklistEntity(user);
        assertTrue(keyring.entityBlacklisted(user));
    }

    function testUnblacklisting() public {
        vm.prank(admin);
        keyring.blacklistEntity(user);
        vm.prank(admin);
        keyring.unblacklistEntity(user);
        assertFalse(keyring.entityBlacklisted(user));
    }
}