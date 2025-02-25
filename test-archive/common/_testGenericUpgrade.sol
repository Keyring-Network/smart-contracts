// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {CoreV2UpgradeGenericMock} from "../mocks/CoreV2UpgradeGenericMock.sol";

interface IUpgradeable {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external;
    function initialize() external;
    function VERSION() external view returns (uint256);
}

contract _testGenericUpgrade is Test {
    string constant UPGRADEFILE = "CoreV2UpgradeGenericMock.sol";

    function _test_Upgrade(uint64 version, address c, address attacker, string memory oldfile_) internal {
        // SETUP UPGRADE
        Options memory opts;
        opts.referenceContract = oldfile_;
        opts.constructorData = abi.encode(version + 1);
        bytes memory initdata = abi.encodeWithSelector(CoreV2UpgradeGenericMock.initialize.selector, "");

        // VALIDATE UPGRADE
        Upgrades.validateUpgrade(UPGRADEFILE, opts);

        // ATTACKER SHOULD NOT BE ABLE TO UPGRADE
        CoreV2UpgradeGenericMock impl = new CoreV2UpgradeGenericMock(version + 1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, attacker));
        vm.prank(attacker);
        IUpgradeable(c).upgradeToAndCall(address(impl), initdata);

        // OWNER SHOULD BE ABLE TO UPGRADE
        Upgrades.upgradeProxy(c, UPGRADEFILE, initdata, opts);

        // SHOULD NOT BE ABLE TO DOUBLE INITIALIZE AFTER UPGRADE
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        IUpgradeable(c).initialize();

        // CHECK THE VERSION AFTER UPGRADE
        assertEq(IUpgradeable(c).VERSION(), version + 1);
    }
}
