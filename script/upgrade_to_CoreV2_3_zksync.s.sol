// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

import {CoreV2_2} from "../src/CoreV2_2.sol";
import {CoreV2_3_zksync} from "../src/CoreV2_3_zksync.sol";

import {Tooling} from "./common/deployments.sol";

string constant OLDFILE = "CoreV2_2.sol";
string constant NEWFILE = "CoreV2_3_zksync.sol";

contract upgrade_to_CoreV2_3_zksync is Script, Tooling {

    function run(string memory chain) external {
        (uint256 deployerPrivateKey, address deployerAddress) = loadPrivk();
        vm.startBroadcast(deployerPrivateKey);
        (address proxy, address keyring) = params(chain);

        Options memory opts;

        // SETUP UPGRADE
        opts.referenceContract = OLDFILE;
        opts.constructorData = abi.encode(address(keyring));
        bytes memory initdata = abi.encodeWithSelector(CoreV2_2.initialize.selector, "");

        // VALIDATE UPGRADE
        Upgrades.validateUpgrade(NEWFILE, opts);

        // PERFORM UPGRADE
        Upgrades.upgradeProxy(
            proxy, 
            NEWFILE, 
            initdata,
            opts
        );

        vm.stopBroadcast();
    }
}