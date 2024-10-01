// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

import {CoreV2} from "../src/CoreV2.sol";

string constant NEWFILE = "CoreV2.sol";

contract CoreV2Deploy is Script {

    function run() external {
        // LOAD ENV VARIABLES
        address keyring = vm.envAddress("KEYRING_CREDENTIALS");
        require(keyring != address(0), "KEYRING_CREDENTIALS not set");
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set");

        address deployerAddress = vm.addr(deployerPrivateKey);
        require(deployerAddress != address(0), "Invalid PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        Options memory opts;
        opts.constructorData = abi.encode(address(keyring));
        Upgrades.deployUUPSProxy(
            NEWFILE,
            abi.encodeCall(CoreV2.initialize, deployerAddress),
            opts
        );

        vm.stopBroadcast();
    }
}