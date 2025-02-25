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
import "../src/CoreV2_3_zksync.sol";

uint64 constant VERSIONNEXT = 3;
string constant BASEFILE = "CoreV2.sol";
string constant OLDFILE = "CoreV2_2.sol";
string constant NEWFILE = "CoreV2_3_zksync.sol";
uint256 constant POLICYID = 1;

contract CoreV2Test is Test, _testGenericUpgrade {
    CoreV2_3_zksync public c3;
    CoreV2_2 public c2;
    KeyringCredentialMock public keyring;
    address public owner;
    address constant attacker = address(0x1500);

    function setUp() public {
        owner = address(this);
        keyring = new KeyringCredentialMock();
        Options memory opts;
        opts.constructorData = abi.encode(address(keyring));
        address proxy = Upgrades.deployUUPSProxy(BASEFILE, abi.encodeCall(CoreV2.initialize, owner), opts);

        // SETUP FIRST UPGRADE
        opts.referenceContract = BASEFILE;
        opts.constructorData = abi.encode(address(keyring));
        bytes memory initdata = abi.encodeWithSelector(CoreV2_2.initialize.selector, "");

        // VALIDATE UPGRADE
        Upgrades.validateUpgrade(OLDFILE, opts);

        // OWNER SHOULD BE ABLE TO UPGRADE
        Upgrades.upgradeProxy(proxy, OLDFILE, initdata, opts);

        c2 = CoreV2_2(proxy);

        // SETUP SECOND UPGRADE
        opts.referenceContract = OLDFILE;
        opts.constructorData = abi.encode();
        initdata = abi.encodeWithSelector(CoreV2_3_zksync.initialize.selector);

        // VALIDATE UPGRADE
        Upgrades.validateUpgrade(NEWFILE, opts);

        // OWNER SHOULD BE ABLE TO UPGRADE
        Upgrades.upgradeProxy(proxy, NEWFILE, initdata, opts);

        c3 = CoreV2_3_zksync(proxy);
    }

    function test_doubleInitialize() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        c3.initialize();
    }

    function test_Upgrade() public {
        _test_Upgrade(VERSIONNEXT, address(c3), attacker, OLDFILE);
    }
}
