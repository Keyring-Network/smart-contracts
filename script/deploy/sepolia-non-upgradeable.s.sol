// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {KeyringCoreV2} from "../../src/KeyringCoreV2.sol";

contract SepoliaCoreV2 is Script {

    function run() external {
        // LOAD ENV VARIABLES
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set");

        vm.startBroadcast(deployerPrivateKey);
        // Deploy the contract
        KeyringCoreV2 c = new KeyringCoreV2();

        console.log("Contract deployed at:", address(c));

        vm.stopBroadcast();
    }
}