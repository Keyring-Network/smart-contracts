// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/console.sol";
import {KeyringCoreBaseTest} from "./KeyringCoreBase.t.sol";

import {IKeyringCore} from "../../src/interfaces/IKeyringCore.sol";

contract KeyringCoreMainFeaturesTest is KeyringCoreBaseTest {
    bytes32 internal testKeyHash;
    bytes internal testKey;

    function setUp() override public {
        vm.chainId(1625247600);
        super.setUp();
        testKey = hex"abcd";
        testKeyHash = keyringCore.getKeyHash(testKey);
    }

    // Constructor and Admin Initialization Test
    function testConstructorInitialAdmin() public {
        assertEq(keyringCore.admin(), admin);
    }

    // Admin Functionality Tests
    function testSetAdminByAdmin() public {
        keyringCore.setAdmin(nonAdmin);
        assertEq(keyringCore.admin(), nonAdmin);
    }

    function testSetAdminByNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrCallerNotAdmin.selector, nonAdmin));
        keyringCore.setAdmin(nonAdmin);
    }

    // Key Registration Tests
    function testRegisterKeyByAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        assertTrue(keyringCore.keyExists(testKeyHash));
    }

    function testRegisterKeyByNonAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrCallerNotAdmin.selector, nonAdmin));
        keyringCore.registerKey(block.chainid, validTo, testKey);
    }

    function testRegisterKeyInvalidTime() public {
        // Skipping that test as nothing is done using validFrom
        vm.skip(true);

        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom - 1 days;
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrInvalidKeyRegistration.selector, "IVP"));
        keyringCore.registerKey(block.chainid, validTo, testKey);
    }

    function testRegisterKeyAlreadyRegistered() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrInvalidKeyRegistration.selector, "KAR"));
        keyringCore.registerKey(block.chainid, validTo, testKey);
    }

    // Key Revocation Tests
    function testRevokeKeyByAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        keyringCore.revokeKey(testKeyHash);
        assertFalse(keyringCore.keyExists(testKeyHash));
    }

    function testRevokeKeyByNonAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrCallerNotAdmin.selector, nonAdmin));
        keyringCore.revokeKey(testKeyHash);
    }

    function testRevokeNonExistentKey() public {
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrKeyNotFound.selector, testKeyHash));
        keyringCore.revokeKey(testKeyHash);
    }

    // Entity Blacklisting Tests
    function testBlacklistEntityByAdmin() public {
        keyringCore.blacklistEntity(1, nonAdmin);
        assertTrue(keyringCore.entityBlacklisted(1, nonAdmin));
    }

    function testBlacklistEntityByNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrCallerNotAdmin.selector, nonAdmin));
        keyringCore.blacklistEntity(1, nonAdmin);
    }

    function testUnblacklistEntityByAdmin() public {
        keyringCore.blacklistEntity(1, nonAdmin);
        keyringCore.unblacklistEntity(1, nonAdmin);
        assertFalse(keyringCore.entityBlacklisted(1, nonAdmin));
    }

    function testUnblacklistEntityByNonAdmin() public {
        keyringCore.blacklistEntity(1, nonAdmin);
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrCallerNotAdmin.selector, nonAdmin));
        keyringCore.unblacklistEntity(1, nonAdmin);
    }



    function testCredentialCreationExpired() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 2 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 2 days;
        uint256 validUntil = block.timestamp + 1 days;
        vm.warp(block.timestamp + 1 days + 1 minutes);

        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrInvalidCredential.selector, 1, nonAdmin, "EXP"));
        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
    }

       // Credential Creation Tests
    function testCreateCredentialWithWrongChainId() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrInvalidCredential.selector, 1, nonAdmin, "CHAINID"));
        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, 1234567890, validUntil, 1 ether, testKey, "", "");
        

    }

    // Credential Creation Tests
    function testCreateCredentialOk() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        uint256 gasBefore = gasleft();
        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
        uint256 gasAfter = gasleft();
        assertTrue(keyringCore.checkCredential(1, nonAdmin));
        emit log_named_uint("Gas for COLD COST credential without RSA validation:", gasBefore - gasAfter);
        validUntil = validUntil + 32 seconds;

        gasBefore = gasleft();
        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
        gasAfter = gasleft();
        emit log_named_uint("Gas for HOT COST credential without RSA validation:", gasBefore - gasAfter);
        validUntil = validUntil + 32 seconds;

        // This test is not valid anymore as we have a check for cost in the createCredential function
        // gasBefore = gasleft();
        // keyringCore.createCredential(nonAdmin, 1, block.chainid, validUntil, 0, testKey, "", "");
        // gasAfter = gasleft();
        // emit log_named_uint("Gas for HOT NO-COST credential without RSA validation:", gasBefore - gasAfter);
        // gasBefore = gasleft();
        // keyringCore.checkCredential(1, nonAdmin);
        // gasAfter = gasleft();
        // emit log_named_uint("Gas for checkCredential:", gasBefore - gasAfter);
    }

    function testCreateCredentialInsufficientPayment() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrInvalidCredential.selector, 1, nonAdmin, "VAL"));
        keyringCore.createCredential{value: 0.5 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
    }

    function testCreateCredentialInvalidKey() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        vm.warp(block.timestamp + 2 days);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrInvalidCredential.selector, 1, nonAdmin, "BDK"));
        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
    }

    function testCreateCredentialBlacklistedEntity() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        keyringCore.blacklistEntity(1, nonAdmin);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrInvalidCredential.selector, 1, nonAdmin, "BLK"));
        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
    }

    function testCreateCredentialExpirationInPast() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 2 days;
        uint256 validUntil = block.timestamp + 1 days;

        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrInvalidCredential.selector, 1, nonAdmin, "BDK"));
        vm.warp(block.timestamp + 2 days);
        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
    }

    // Fee Collection Tests
    function testCollectFeesByAdmin() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
        uint256 balanceBefore = address(this).balance;
        uint256 keyringBalanceBefore = address(keyringCore).balance;
        keyringCore.collectFees(admin);
        uint256 balanceAfter = address(this).balance;
        uint256 keyringBalanceAfter = address(keyringCore).balance;
        assertEq(balanceAfter, balanceBefore + 1 ether);
        assertEq(keyringBalanceAfter, keyringBalanceBefore - 1 ether);
    }

    function testCollectFeesByNonAdmin() public {
        vm.prank(nonAdmin);
        vm.expectRevert(abi.encodeWithSelector(IKeyringCore.ErrCallerNotAdmin.selector, nonAdmin));
        keyringCore.collectFees(address(this));
    }

    // View Function Tests
    function testAdmin() public {
        assertEq(keyringCore.admin(), admin);
    }

    function testGetKeyHash() public {
        assertEq(keyringCore.getKeyHash(testKey), testKeyHash);
    }

    function testKeyExists() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        assertTrue(keyringCore.keyExists(testKeyHash));
        keyringCore.revokeKey(testKeyHash);
        assertFalse(keyringCore.keyExists(testKeyHash));
    }



    function testKeyValidTo() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        assertEq(keyringCore.keyValidTo(testKeyHash), validTo);
    }

    function testKeyDetails() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        IKeyringCore.KeyEntry memory kd = keyringCore.keyDetails(testKeyHash);
        assertEq(kd.chainId, block.chainid);
        assertEq(kd.validTo, validTo);
        assertTrue(kd.isValid);
    }

    function testEntityBlacklisted() public {
        keyringCore.blacklistEntity(1, nonAdmin);
        assertTrue(keyringCore.entityBlacklisted(1, nonAdmin));
        keyringCore.unblacklistEntity(1, nonAdmin);
        assertFalse(keyringCore.entityBlacklisted(1, nonAdmin));
    }

    function testEntityExp() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
            keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
        assertEq(keyringCore.entityExp(1, nonAdmin), validUntil);
    }

    function testEntityData() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
        IKeyringCore.EntityData memory ed = keyringCore.entityData(1, nonAdmin);
        assertTrue(ed.exp == keyringCore.entityExp(1, nonAdmin));
        assertTrue(ed.blacklisted == false);
    }

    function testCheckCredential() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
        assertTrue(keyringCore.checkCredential(1, nonAdmin));
    }

    function testCheckCredentialExpired() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
        uint256 ts = block.timestamp + 2 days;
        vm.warp(ts + 1);
        assertFalse(keyringCore.checkCredential(1, nonAdmin)); // Should fail due to expiration
    }

    function testCheckCredentialBlacklisted() public {
        uint256 validFrom = block.timestamp;
        uint256 validTo = validFrom + 1 days;
        keyringCore.registerKey(block.chainid, validTo, testKey);
        uint256 createBefore = block.timestamp + 5 minutes;
        uint256 validUntil = block.timestamp + 1 days;

        keyringCore.createCredential{value: 1 ether}(nonAdmin, 1, block.chainid, validUntil, 1 ether, testKey, "", "");
        keyringCore.blacklistEntity(1, nonAdmin);
        assertFalse(keyringCore.checkCredential(1, nonAdmin)); // Should fail due to blacklisting
    }

    fallback() external payable {}
}