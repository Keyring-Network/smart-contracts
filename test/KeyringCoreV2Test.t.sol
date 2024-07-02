// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KeyringCoreV2.sol";

contract KeyringCoreV2BaseTestRig is KeyringCoreV2Base {

    constructor() KeyringCoreV2Base() {}

}

contract KeyringCoreV2BaseTest is Test {
    KeyringCoreV2BaseTestRig internal keyring;
    address internal admin;
    address internal nonAdmin;
    bytes32 internal testKeyHash;
    bytes internal testKey;

    function setUp() public {
        admin = address(this);
        nonAdmin = address(0x123);
        keyring = new KeyringCoreV2BaseTestRig();
        testKey = hex"abcd";
        testKeyHash = keyring.getKeyHash(testKey);
        uint256 BASETIME = keyring.BASETIME();
        uint256 EPOCHLENGTH = keyring.EPOCHLENGTH();
        vm.warp(BASETIME+EPOCHLENGTH*10);
    }

    // Access Control Tests
    function testSetAdminByAdmin() public {
        keyring.setAdmin(nonAdmin);
        assertEq(keyring.admin(), nonAdmin);
    }

    function testSetAdminByNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.setAdmin(nonAdmin);
    }

    // Key Management Tests
    function testRegisterKey() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        assertTrue(keyring.keyExists(testKeyHash));
    }

    function testRevokeKey() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        keyring.revokeKey(testKeyHash);
        assertFalse(keyring.keyExists(testKeyHash));
    }

    // Entity Management Tests
    function testBlacklistEntity() public {
        keyring.blacklistEntity(1, nonAdmin);
        assertTrue(keyring.entityBlacklisted(1, nonAdmin));
    }

    function testUnblacklistEntity() public {
        keyring.blacklistEntity(1, nonAdmin);
        keyring.unblacklistEntity(1, nonAdmin);
        assertFalse(keyring.entityBlacklisted(1, nonAdmin));
    }

    // Credential Creation Tests
    function testCreateCredential() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        uint32 currentEpoch = keyring.getCurrentEpoch();
        uint32 nextEpoch = currentEpoch + 1;

        keyring.registerKey(validFrom, validTo, testKey);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, currentEpoch, nextEpoch, 1 ether, testKey, "", "");
        assertTrue(keyring.checkCredential(1, nonAdmin));
    }

    // Check Credential Failure Modes
    function testCheckCredentialExpired() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        uint32 currentEpoch = keyring.getCurrentEpoch();
        uint32 nextEpoch = currentEpoch + 1;

        keyring.registerKey(validFrom, validTo, testKey);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, currentEpoch-2, nextEpoch-1, 1 ether, testKey, "", "");
        uint256 ts = keyring.getTimeForEndOfEpoch(nextEpoch);
        vm.warp(ts+1);
        assertFalse(keyring.checkCredential(1, nonAdmin)); // Should fail due to expiration
    }

    function testCheckCredentialBlacklisted() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        uint32 currentEpoch = keyring.getCurrentEpoch();
        uint32 nextEpoch = currentEpoch + 1;

        keyring.registerKey(validFrom, validTo, testKey);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, currentEpoch, nextEpoch, 1 ether, testKey, "", "");
        keyring.blacklistEntity(1, nonAdmin);
        assertFalse(keyring.checkCredential(1, nonAdmin)); // Should fail due to blacklisting
    }

    // View Function Tests
    function testAdmin() public {
        assertEq(keyring.admin(), admin);
    }

    function testKeyDetails() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        KeyringCoreV2Base.KeyEntry memory kd = keyring.keyDetails(testKeyHash);
        bool isValid = kd.isValid;
        assertTrue(isValid);
    }

    // Utility Function Tests
    function testEpochCalculations() public {
        uint32 expectedEpoch = keyring.getEpochForTime(block.timestamp);
        assertEq(keyring.getCurrentEpoch(), expectedEpoch);
    }
}