// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/unsafe/KeyringCoreV2Unsafe.sol";
import "../src/lib/RsaMessagePacking.sol";
import "../src/interfaces/ICoreV2Base.sol";

contract KeyringCoreV2UnsafeTest is Test {
    KeyringCoreV2Unsafe internal keyring;
    address internal admin;
    address internal nonAdmin;
    bytes32 internal testKeyHash;
    bytes internal testKey;

    function setUp() public {
        admin = address(this);
        nonAdmin = address(0x123);
        keyring = new KeyringCoreV2Unsafe();
        testKey = hex"abcd";
        testKeyHash = keyring.getKeyHash(testKey);
        vm.warp(1704067200); // 01-01-2024 00:00:00
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
        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
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
        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.registerKey(validFrom, validTo, testKey);
    }

    function testRegisterKeyInvalidTime() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom - 1 days;
        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrInvalidKeyRegistration.selector, "IVP"));
        keyring.registerKey(validFrom, validTo, testKey);
    }

    function testRegisterKeyAlreadyRegistered() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrInvalidKeyRegistration.selector, "KAR"));
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
        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.revokeKey(testKeyHash);
    }

    function testRevokeNonExistentKey() public {
        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrKeyNotFound.selector, testKeyHash));
        keyring.revokeKey(testKeyHash);
    }

    // Entity Blacklisting Tests
    function testBlacklistEntityByAdmin() public {
        keyring.blacklistEntity(1, nonAdmin);
        assertTrue(keyring.entityBlacklisted(1, nonAdmin));
    }

    function testBlacklistEntityByNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
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
        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.unblacklistEntity(1, nonAdmin);
    }

    function testCredentialCreationExpired() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 2 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 createBefore = block.timestamp + 2 days;
        uint256 validUntil = block.timestamp + 1 days;
        vm.warp(block.timestamp + 1 days + 1 minutes);

        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "EXP"));
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
    }

    // Credential Creation Tests
    function testCreateCredentialOk() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        uint256 gasBefore = gasleft();
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
        uint256 gasAfter = gasleft();
        assertTrue(keyring.checkCredential(1, nonAdmin));
        emit log_named_uint("Gas for COLD COST credential without RSA validation:", gasBefore - gasAfter);
        validUntil = validUntil + 32 seconds;

        gasBefore = gasleft();
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
        gasAfter = gasleft();
        emit log_named_uint("Gas for HOT COST credential without RSA validation:", gasBefore - gasAfter);
        validUntil = validUntil + 32 seconds;

        gasBefore = gasleft();
        keyring.createCredential(nonAdmin, 1, createBefore, validUntil, 0, testKey, "", "");
        gasAfter = gasleft();
        emit log_named_uint("Gas for HOT NO-COST credential without RSA validation:", gasBefore - gasAfter);
        gasBefore = gasleft();
        keyring.checkCredential(1, nonAdmin);
        gasAfter = gasleft();
        emit log_named_uint("Gas for checkCredential:", gasBefore - gasAfter);
    }

    function testCreateCredentialInsufficientPayment() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "VAL"));
        keyring.createCredential{value: 0.5 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
    }

    function testCreateCredentialInvalidKey() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        vm.warp(block.timestamp + 2 days);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "BDK"));
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
    }

    function testCreateCredentialBlacklistedEntity() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        keyring.blacklistEntity(1, nonAdmin);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "BLK"));
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
    }

    function testCreateCredentialExpirationInPast() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 createBefore = block.timestamp + 2 days;
        uint256 validUntil = block.timestamp + 1 days;

        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrInvalidCredential.selector, 1, nonAdmin, "BDK"));
        vm.warp(block.timestamp + 2 days);
        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
    }

    // Fee Collection Tests
    function testCollectFeesByAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
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
        vm.expectRevert(abi.encodeWithSelector(ICoreV2Base.ErrCallerNotAdmin.selector, 0x0000000000000000000000000000000000000123));
        keyring.collectFees(address(this));
    }

    // View Function Tests
    function testAdmin() public {
        assertEq(keyring.admin(), admin);
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
        ICoreV2Base.KeyEntry memory kd = keyring.keyDetails(testKeyHash);
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
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
        assertEq(keyring.entityExp(1, nonAdmin), validUntil);
    }

    function testEntityData() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
        ICoreV2Base.EntityData memory ed = keyring.entityData(1, nonAdmin);
        assertTrue(ed.exp == keyring.entityExp(1, nonAdmin));
        assertTrue(ed.blacklisted == false);
    }

    function testCheckCredential() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
        assertTrue(keyring.checkCredential(1, nonAdmin));
    }

    function testCheckCredentialExpired() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
        uint256 ts = block.timestamp + 2 days;
        vm.warp(ts + 1);
        assertFalse(keyring.checkCredential(1, nonAdmin)); // Should fail due to expiration
    }

    function testCheckCredentialBlacklisted() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyring.registerKey(validFrom, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyring.createCredential{value: 1 ether}(nonAdmin, 1, createBefore, validUntil, 1 ether, testKey, "", "");
        keyring.blacklistEntity(1, nonAdmin);
        assertFalse(keyring.checkCredential(1, nonAdmin)); // Should fail due to blacklisting
    }

    fallback() external payable {}
}
