// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../src/KeyringCoreV2.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy the contract
        KeyringCoreV2 c = new KeyringCoreV2();

        console.log("Contract deployed at:", address(c));

        vm.stopBroadcast();
    }
}