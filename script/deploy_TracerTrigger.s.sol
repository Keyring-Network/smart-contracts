// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {TracerTrigger} from "../src/tooling/TracerTrigger.sol";

import {Tooling} from "./common/deployments.sol";

contract deploy_TracerTrigger is Script, Tooling {

    function run(string memory chain) external {
        (uint256 deployerPrivateKey, address deployerAddress) = loadPrivk();
        vm.startBroadcast(deployerPrivateKey);
        (address proxy, address keyring) = params(chain);
        
        // Deploy the contract
        TracerTrigger c = new TracerTrigger(proxy);

        console.log("Contract deployed at:", address(c));

        vm.stopBroadcast();
    }
}