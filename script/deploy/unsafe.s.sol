// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../../src/unsafe/KeyringCoreV2Unsafe.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy the contract
        KeyringCoreV2Unsafe c = new KeyringCoreV2Unsafe();

        console.log("Contract deployed at:", address(c));

        vm.stopBroadcast();
    }
}