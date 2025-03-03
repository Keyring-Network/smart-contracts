// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {KeyringCoreBaseTest} from "./KeyringCoreBase.t.sol";

import {AlwaysValidSignatureChecker} from "../../src/messageVerifiers/AlwaysValidSignatureChecker.sol";

contract KeyringCoreAdminFeaturesTest is KeyringCoreBaseTest {

    address public feeRecipient = address(0x3);
    address public blacklistedEntity = address(0x4);
    bytes public key = "0x1234";
    uint256 public validTo = 2000;
    uint256 public policyId = 1;


    function testSetAdmin() public {
        console.log(address(this));
        address newAdmin = address(0xdead);
        keyringCore.setAdmin(newAdmin);
        assertEq(keyringCore.admin(), newAdmin);
        
        vm.prank(newAdmin);
        keyringCore.setAdmin(admin);
        assertEq(keyringCore.admin(), admin);
    }


    function testRegisterAndRevokeKey() public {
        keyringCore.registerKey(block.chainid, validTo, key);
        bytes32 keyHash = keccak256(key);
        assertTrue(keyringCore.keyExists(keyHash));
        
        keyringCore.revokeKey(keyHash);
        assertFalse(keyringCore.keyExists(keyHash));
    }

    function testBlacklistAndUnblacklistEntity() public {
        keyringCore.blacklistEntity(policyId, blacklistedEntity);
        assertTrue(keyringCore.entityBlacklisted(policyId, blacklistedEntity));
        
        keyringCore.unblacklistEntity(policyId, blacklistedEntity);
        assertFalse(keyringCore.entityBlacklisted(policyId, blacklistedEntity));
    }

    function testCollectFees() public {
        // Send some ETH to the contract
        vm.deal(address(keyringCore), 1 ether);
        
        // Collect fees
        keyringCore.collectFees(feeRecipient);
        assertEq(feeRecipient.balance, 1 ether);
    }

    function testFailSetAdminFromNonAdmin() public {
        vm.prank(nonAdmin);
        keyringCore.setAdmin(address(0x5));
    }

    function testFailRegisterKeyFromNonAdmin() public {
        vm.prank(nonAdmin);
        keyringCore.registerKey(block.chainid, validTo, key);
    }

    function testFailRevokeKeyFromNonAdmin() public {
        keyringCore.registerKey(block.chainid, validTo, key);
        bytes32 keyHash = keccak256(key);
        
        vm.prank(nonAdmin);
        keyringCore.revokeKey(keyHash);
    }

    function testFailBlacklistEntityFromNonAdmin() public {
        vm.prank(nonAdmin);
        keyringCore.blacklistEntity(policyId, blacklistedEntity);
    }

    function testFailUnblacklistEntityFromNonAdmin() public {
        keyringCore.blacklistEntity(policyId, blacklistedEntity);
        
        vm.prank(nonAdmin);
        keyringCore.unblacklistEntity(policyId, blacklistedEntity);
    }

    function testFailCollectFeesFromNonAdmin() public {
        vm.deal(address(keyringCore), 1 ether);
        
        vm.prank(nonAdmin);
        keyringCore.collectFees(feeRecipient);
    }

} 