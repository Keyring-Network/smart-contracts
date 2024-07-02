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

    // Constructor and Admin Initialization Test
    function testConstructorInitialAdmin() public {
        assertEq(keyring.admin(), admin);
    }

    // Admin Functionality Tests
    function testSetAdminByAdmin() public {
        keyring.setAdmin(nonAdmin);
        assertEq(keyring.admin(), nonAdmin);
    }

    function testSetAdminByNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.setAdmin(nonAdmin);
    }

    // Key Registration Tests
    function testRegisterKeyByAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        assertTrue(keyring.keyExists(testKeyHash));
    }

    function testRegisterKeyByNonAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.registerKey(validFrom, validTo, testKey);
    }

    function testRegisterKeyInvalidTime() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom - 1 days;
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrInvalidKeyRegistration.selector, "IVP"));
        keyring.registerKey(validFrom, validTo, testKey);
    }

    function testRegisterKeyAlreadyRegistered() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrInvalidKeyRegistration.selector, "KAR"));
        keyring.registerKey(validFrom, validTo, testKey);
    }

    // Key Revocation Tests
    function testRevokeKeyByAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        keyring.revokeKey(testKeyHash);
        assertFalse(keyring.keyExists(testKeyHash));
    }

    function testRevokeKeyByNonAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.revokeKey(testKeyHash);
    }

    function testRevokeNonExistentKey() public {
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrKeyNotFound.selector, testKeyHash));
        keyring.revokeKey(testKeyHash);
    }

    // Entity Blacklisting Tests
    function testBlacklistEntityByAdmin() public {
        keyring.blacklistEntity(1, nonAdmin);
        assertTrue(keyring.entityBlacklisted(1, nonAdmin));
    }

    function testBlacklistEntityByNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.blacklistEntity(1, nonAdmin);
    }

    function testUnblacklistEntityByAdmin() public {
        keyring.blacklistEntity(1, nonAdmin);
        keyring.unblacklistEntity(1, nonAdmin);
        assertFalse(keyring.entityBlacklisted(1, nonAdmin));
    }

    function testUnblacklistEntityByNonAdmin() public {
        keyring.blacklistEntity(1, nonAdmin);
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.unblacklistEntity(1, nonAdmin);
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

    function testCreateCredentialInsufficientPayment() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        uint32 currentEpoch = keyring.getCurrentEpoch();
        uint32 nextEpoch = currentEpoch + 1;

        keyring.registerKey(validFrom, validTo, testKey);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "VAL"));
        keyring.createCredential{value: 0.5 ether}(nonAdmin, 1, currentEpoch, nextEpoch, 1 ether, testKey, "", "");
    }

    function testCreateCredentialInvalidKey() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom - 1 days;
        uint32 currentEpoch = keyring.getCurrentEpoch();
        uint32 nextEpoch = currentEpoch + 1;

        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "BDK"));
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, currentEpoch, nextEpoch, 1 ether, testKey, "", "");
    }

    function testCreateCredentialOutsideEpoch() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        uint32 currentEpoch = keyring.getCurrentEpoch();
        uint32 nextEpoch = currentEpoch + 1;

        keyring.registerKey(validFrom, validTo, testKey);
        vm.warp(keyring.getTimeForEndOfEpoch(currentEpoch) + 5);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "EPO"));
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, currentEpoch-2, nextEpoch-1, 1 ether, testKey, "", "");
    }

    function testCreateCredentialBlacklistedEntity() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        uint32 currentEpoch = keyring.getCurrentEpoch();
        uint32 nextEpoch = currentEpoch + 1;

        keyring.registerKey(validFrom, validTo, testKey);
        keyring.blacklistEntity(1, nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "BLK"));
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, currentEpoch, nextEpoch, 1 ether, testKey, "", "");
    }

    function testCreateCredentialExpirationInPast() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        uint32 currentEpoch = keyring.getCurrentEpoch();
        uint32 nextEpoch = currentEpoch;

        keyring.registerKey(validFrom, validTo, testKey);
        vm.warp(keyring.getTimeForEndOfEpoch(currentEpoch+1));
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "EXP"));
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, currentEpoch, nextEpoch, 1 ether, testKey, "", "");
    }

    // Fee Collection Tests
    function testCollectFeesByAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, keyring.getCurrentEpoch(), keyring.getCurrentEpoch() + 1, 1 ether, testKey, "", "");
        uint256 balanceBefore = address(this).balance;
        uint256 keyringBalanceBefore = address(keyring).balance;
        keyring.collectFees(admin);
        uint256 balanceAfter = address(this).balance;
        uint256 keyringBalanceAfter = address(keyring).balance;
        assertEq(balanceAfter, balanceBefore + 1 ether);
        assertEq(keyringBalanceAfter, keyringBalanceBefore - 1 ether);
    }

    function testCollectFeesByNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(KeyringCoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.collectFees(address(this));
    }

    // View Function Tests
    function testAdmin() public {
        assertEq(keyring.admin(), admin);
    }

    function testGetTimeForEndOfEpoch() public {
        uint256 currentTime = block.timestamp;
        uint256 expectedEndTime = currentTime + keyring.EPOCHLENGTH();
        assertEq(keyring.getTimeForEndOfEpoch(keyring.getCurrentEpoch()), expectedEndTime);
    }

    function testGetTimeForStartOfEpoch() public {
        uint256 currentTime = block.timestamp;
        uint256 expectedStartTime = currentTime - (currentTime % keyring.EPOCHLENGTH());
        assertEq(keyring.getTimeForStartOfEpoch(keyring.getCurrentEpoch()), expectedStartTime);
    }

    function testGetCurrentEpoch() public {
        uint32 expectedEpoch = keyring.getEpochForTime(block.timestamp);
        assertEq(keyring.getCurrentEpoch(), expectedEpoch);
    }

    function testGetEpochForTime() public {
        uint256 currentTime = block.timestamp;
        uint32 expectedEpoch = uint32((currentTime - keyring.BASETIME()) / keyring.EPOCHLENGTH());
        assertEq(keyring.getEpochForTime(currentTime), expectedEpoch);
    }

    function testGetKeyHash() public {
        assertEq(keyring.getKeyHash(testKey), testKeyHash);
    }

    function testKeyExists() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        assertTrue(keyring.keyExists(testKeyHash));
        keyring.revokeKey(testKeyHash);
        assertFalse(keyring.keyExists(testKeyHash));
    }

    function testKeyValidFrom() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        assertEq(keyring.keyValidFrom(testKeyHash), validFrom);
    }

    function testKeyValidTo() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        assertEq(keyring.keyValidTo(testKeyHash), validTo);
    }

    function testKeyDetails() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        KeyringCoreV2Base.KeyEntry memory kd = keyring.keyDetails(testKeyHash);
        assertEq(kd.validFrom, validFrom);
        assertEq(kd.validTo, validTo);
        assertTrue(kd.isValid);
    }

    function testEntityBlacklisted() public {
        keyring.blacklistEntity(1, nonAdmin);
        assertTrue(keyring.entityBlacklisted(1, nonAdmin));
        keyring.unblacklistEntity(1, nonAdmin);
        assertFalse(keyring.entityBlacklisted(1, nonAdmin));
    }

    function testEntityExp() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 expTime = keyring.getTimeForEndOfEpoch(keyring.getCurrentEpoch()+1);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, keyring.getCurrentEpoch(), keyring.getCurrentEpoch() + 1, 1 ether, testKey, "", "");
        assertEq(keyring.entityExp(1, nonAdmin), expTime);
    }

    function testEntityData() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, keyring.getCurrentEpoch(), keyring.getCurrentEpoch() + 1, 1 ether, testKey, "", "");
        KeyringCoreV2Base.EntityData memory ed = keyring.entityData(1, nonAdmin);
        assertTrue(ed.exp == keyring.entityExp(1, nonAdmin));
        assertTrue(ed.blacklisted == false);
    }

    function testCheckCredential() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, keyring.getCurrentEpoch(), keyring.getCurrentEpoch() + 1, 1 ether, testKey, "", "");
        assertTrue(keyring.checkCredential(1, nonAdmin));
    }

    function testCheckCredentialExpired() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, keyring.getCurrentEpoch() - 2, keyring.getCurrentEpoch() - 1, 1 ether, testKey, "", "");
        uint256 ts = keyring.getTimeForEndOfEpoch(keyring.getCurrentEpoch());
        vm.warp(ts + 1);
        assertFalse(keyring.checkCredential(1, nonAdmin)); // Should fail due to expiration
    }

    function testCheckCredentialBlacklisted() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, keyring.getCurrentEpoch(), keyring.getCurrentEpoch() + 1, 1 ether, testKey, "", "");
        keyring.blacklistEntity(1, nonAdmin);
        assertFalse(keyring.checkCredential(1, nonAdmin)); // Should fail due to blacklisting
    }

    fallback() external payable {}
}
