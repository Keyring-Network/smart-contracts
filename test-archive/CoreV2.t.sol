// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {CoreV2} from "../src/CoreV2.sol";
import {KeyringCredentialMock} from "./mocks/KeyringCredentialMock.sol";
import {CoreV2UpgradeMock} from "./mocks/CoreV2UpgradeMock.sol";
import {CoreV2UpgradeMockV2} from "./mocks/CoreV2UpgradeMockV2.sol";

contract CoreV2Test is Test {
    CoreV2 public c;
    KeyringCredentialMock public keyring;
    address public owner;
    address constant attacker = address(0x1500);

    function setUp() public {
        owner = address(this);
        keyring = new KeyringCredentialMock();
        Options memory opts;
        opts.constructorData = abi.encode(address(keyring));
        address proxy = Upgrades.deployUUPSProxy("CoreV2.sol", abi.encodeCall(CoreV2.initialize, owner), opts);
        c = CoreV2(proxy);
    }

    function test_CREDENTIALCACHE() public view {
        assertEq(c.CREDENTIALCACHE(), address(keyring));
    }

    function test_CheckCredential() public {
        assertEq(c.checkCredential(1, address(this)), false);
        keyring.set(address(this), 1, true);
        assertEq(c.checkCredential(1, address(this)), true);
        keyring.set(address(this), 1, false);
        assertEq(c.checkCredential(1, address(this)), false);
    }

    function test_PolicyOverflows() public {
        vm.expectRevert(CoreV2.PolicyOverflows.selector);
        c.checkCredential(type(uint256).max, address(this));
    }

    function test_doubleInitialize() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        c.initialize(address(keyring));
    }

    function test_Upgrade() public {
        // SETUP UPGRADE
        Options memory opts;
        opts.referenceContract = "CoreV2.sol";
        opts.constructorData = abi.encode(address(keyring));
        bytes memory initdata = abi.encodeWithSelector(CoreV2UpgradeMock.initialize.selector, "");

        // VALIDATE UPGRADE
        Upgrades.validateUpgrade("CoreV2UpgradeMock.sol", opts);

        // ATTACKER SHOULD NOT BE ABLE TO UPGRADE
        CoreV2UpgradeMock impl = new CoreV2UpgradeMock(address(keyring));
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, attacker));
        vm.prank(attacker);
        c.upgradeToAndCall(address(impl), initdata);

        // OWNER SHOULD BE ABLE TO UPGRADE
        Upgrades.upgradeProxy(address(c), "CoreV2UpgradeMock.sol", initdata, opts);

        // CHECK CREDENTIAL CHECKING STILL WORKS
        assertEq(c.checkCredential(1, address(this)), false);
        keyring.set(address(this), 1, true);
        assertEq(c.checkCredential(1, address(this)), true);
        keyring.set(address(this), 1, false);
        assertEq(c.checkCredential(1, address(this)), false);
        CoreV2UpgradeMock cc = CoreV2UpgradeMock(address(c));

        // CHECK NEW CONSTANT IS ACCESSIBLE
        assertEq(cc.TEST(), keccak256("TEST"));

        // SHOULD NOT BE ABLE TO DOUBLE INITIALIZE AFTER UPGRADE
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        cc.initialize();

        //////////////////////////////////////////////////////////
        // RE-UPGRADE TO TEST FUTURE UPGRADE LOGIC
        //////////////////////////////////////////////////////////

        // SETUP RE-UPGRADE
        opts.referenceContract = "CoreV2UpgradeMock.sol";

        // VALIDATE RE-UPGRADE
        Upgrades.validateUpgrade("CoreV2UpgradeMockV2.sol", opts);

        // ATTACKER SHOULD NOT BE ABLE TO RE-UPGRADE
        CoreV2UpgradeMockV2 impl2 = new CoreV2UpgradeMockV2();
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, attacker));
        vm.prank(attacker);
        c.upgradeToAndCall(address(impl2), initdata);

        // OWNER SHOULD BE ABLE TO RE-UPGRADE
        Upgrades.upgradeProxy(address(c), "CoreV2UpgradeMockV2.sol", initdata, opts);

        // CHECK CREDEINTIAL CACHE IS NEW VALUE
        assertEq(c.CREDENTIALCACHE(), address(1));

        // CHECK FORCED PASS WORKS
        assertEq(c.checkCredential(2, address(this)), true);
    }
}
