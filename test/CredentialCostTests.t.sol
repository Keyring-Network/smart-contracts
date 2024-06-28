// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KeyringCoreV2.sol";

contract CredentialCostTests is Test {
    KeyringCoreV2 keyring;
    address admin = address(0x1);
    uint256 policyId = 1;

    function setUp() public {
        keyring = new KeyringCoreV2();
        keyring.transferOwnership(admin);
    }

    function testInitialCredentialCost() public {
        assertEq(keyring.credentialCost(policyId), 0);
    }

    function testCredentialCostSetting() public {
        uint256 cost = 1 ether;
        vm.prank(admin);
        keyring.setCredentialCost(policyId, cost);
        assertEq(keyring.credentialCost(policyId), cost);
    }
}