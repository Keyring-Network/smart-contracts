// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {KeyringCoreV2} from "../../src/static/KeyringCoreV2.sol";
import {Tooling} from "./common/deployments.sol";

contract SepoliaCoreV2 is Script, Tooling {

    function run() external {
        (uint256 deployerPrivateKey, address deployerAddress) = loadPrivk();
        vm.startBroadcast(deployerPrivateKey);
        // Deploy the contract
        KeyringCoreV2 c = new KeyringCoreV2();

        console.log("Contract deployed at:", address(c));

        vm.stopBroadcast();
    }
}