// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {CoreV2} from "../src/CoreV2.sol";
import {KeyringCredentialMock} from "./mocks/KeyringCredentialMock.sol";

import {_testGenericUpgrade} from "./common/_testGenericUpgrade.sol";

import "../src/CoreV2_2.sol";

uint64 constant VERSIONNEXT = 2;
string constant OLDFILE = "CoreV2.sol";
string constant NEWFILE = "CoreV2_2.sol";
uint256 constant POLICYID = 1;

contract CoreV2Test is Test, _testGenericUpgrade {
    CoreV2_2 public c;
    KeyringCredentialMock public keyring;
    address public owner;
    address constant attacker = address(0x1500);

    function setUp() public {
        owner = address(this);
        keyring = new KeyringCredentialMock();
        Options memory opts;
        opts.constructorData = abi.encode(address(keyring));
        address proxy = Upgrades.deployUUPSProxy(
            OLDFILE,
            abi.encodeCall(CoreV2.initialize, owner),
            opts
        );

        // SETUP UPGRADE
        opts.referenceContract = OLDFILE;
        opts.constructorData = abi.encode(address(keyring));
        bytes memory initdata = abi.encodeWithSelector(CoreV2_2.initialize.selector, "");

        // VALIDATE UPGRADE
        Upgrades.validateUpgrade(NEWFILE, opts);

        // OWNER SHOULD BE ABLE TO UPGRADE
        Upgrades.upgradeProxy(
            proxy, 
            NEWFILE, 
            initdata,
            opts
        );

        c = CoreV2_2(proxy);
    }

    function test_CREDENTIALCACHE() public view {
        assertEq(c.CREDENTIALCACHE(), address(keyring));
    }

    function test_CheckCredential() public {
        assertEq(c.checkCredential(POLICYID, address(this)), false);
        assertEq(c.checkCredential(address(this), uint32(POLICYID)), false);
        keyring.set(address(this), POLICYID, true);
        assertEq(c.checkCredential(POLICYID, address(this)), true);
        assertEq(c.checkCredential(address(this), uint32(POLICYID)), true);
        keyring.set(address(this), POLICYID, false);
        assertEq(c.checkCredential(POLICYID, address(this)), false);
        assertEq(c.checkCredential(address(this), uint32(POLICYID)), false);
    }
    function test_PolicyOverflows() public {
        vm.expectRevert(CoreV2.PolicyOverflows.selector);
        c.checkCredential(type(uint256).max, address(this));
    }

    function test_doubleInitialize() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        c.initialize();
    }

    function test_Upgrade() public {
        _test_Upgrade(VERSIONNEXT, address(c), attacker, OLDFILE);
    }

}
