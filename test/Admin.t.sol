// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/admin/KeyringCoreV2AdminProxy.sol";
import {KeyringCoreV2Unsafe} from "../src/unsafe/KeyringCoreV2Unsafe.sol";


contract KeyringCoreV2AdminProxyTest is Test {
    KeyringCoreV2AdminProxy public adminProxy;
    KeyringCoreV2Unsafe public coreContract;

    address public masterAdmin = address(this);
    address public keyManagerAdmin = address(0x2);
    address public credentialAdmin = address(0x3);
    address public feeCollectorAdmin = address(0x4);
    address public unblacklistManagerAdmin = address(0x5);
    address public blacklistManager = address(0x6);
    address public newMasterAdmin = address(0x7);
    address public feeRecipient = address(0x8);
    address public blacklistedEntity = address(0x9);
    address public newBaseAdmin = address(0xA);
    bytes public rsaKey = "0x1234";
    uint256 public validFrom = 1000;
    uint256 public validTo = 2000;
    uint256 public policyId = 1;

    function setUp() public {
        coreContract = new KeyringCoreV2Unsafe();
        adminProxy = new KeyringCoreV2AdminProxy(address(coreContract), masterAdmin);
        coreContract.setAdmin(address(adminProxy));
    }

    function testSetMasterAdmin() public {
        vm.prank(masterAdmin);
        adminProxy.setMasterAdmin(newMasterAdmin);
        assertEq(adminProxy.masterAdmin(), newMasterAdmin);
        vm.prank(newMasterAdmin);
        adminProxy.setMasterAdmin(masterAdmin);
        assertEq(adminProxy.masterAdmin(), masterAdmin);
    }

    function testSetKeyManagerAdmin() public {
        vm.prank(masterAdmin);
        adminProxy.setKeyManagerAdmin(keyManagerAdmin);
        assertEq(adminProxy.keyManagerAdmin(), keyManagerAdmin);
    }

    function testSetFeeCollectorAdmin() public {
        vm.prank(masterAdmin);
        adminProxy.setFeeCollectorAdmin(feeCollectorAdmin);
        assertEq(adminProxy.feeCollectorAdmin(), feeCollectorAdmin);
    }

    function testAddRemoveBlacklistManager() public {
        vm.prank(masterAdmin);
        adminProxy.addBlacklistManager(policyId, blacklistManager);
        vm.prank(masterAdmin);
        adminProxy.removeBlacklistManager(policyId, blacklistManager);
        assertFalse(adminProxy.blacklistManagers(policyId, blacklistManager));
    }

    function testRegisterAndRevokeKey() public {
        vm.prank(masterAdmin);
        adminProxy.setKeyManagerAdmin(keyManagerAdmin);
        vm.prank(keyManagerAdmin);
        adminProxy.registerKey(validFrom, validTo, rsaKey);
        vm.prank(keyManagerAdmin);
        bytes32 keyHash = keccak256(rsaKey);
        adminProxy.revokeKey(keyHash);
        KeyringCoreV2Unsafe.KeyEntry memory key = coreContract.keyDetails(keyHash);
        assertEq(key.isValid, false);
    }

    function testCollectFees() public {
        vm.prank(masterAdmin);
        adminProxy.setFeeCollectorAdmin(feeCollectorAdmin);
        vm.prank(feeCollectorAdmin);
        adminProxy.collectFees(feeRecipient);
    }
    /*
    TODO:
    FIX THIS AND CHECK THE UNBLACKLIST AND BLACKLIST LOGIC
    function testSetAdminOnBaseContract() public {
        vm.prank(masterAdmin);
        adminProxy.setAdminOnBaseContract(newBaseAdmin);
        assertEq(coreContract.admin(), newBaseAdmin);
    }


    */
}