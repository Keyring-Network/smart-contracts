// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

import {CoreV2_2} from "../src/CoreV2_2.sol";
import {CoreV2_3} from "../src/CoreV2_3.sol";

import "./common/deployments.sol";

string constant OLDFILE = "CoreV2_2.sol";
string constant NEWFILE = "CoreV2_3.sol";

contract upgrade_to_CoreV2_3 is Script {

    function run(string memory chain) external {
        // LOAD ENV VARIABLES
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set");

        address deployerAddress = vm.addr(deployerPrivateKey);
        require(deployerAddress != address(0), "Invalid PRIVATE_KEY");
        console.log("DEPLOYER: %s", deployerAddress);

        vm.startBroadcast(deployerPrivateKey);

        bytes32 STAGING = keccak256(abi.encodePacked("STAGING"));
        bytes32 UAT = keccak256(abi.encodePacked("UAT"));
        bytes32 PROD = keccak256(abi.encodePacked("PROD"));
        bytes32 ARBITRUM = keccak256(abi.encodePacked("ARBITRUM"));
        bytes32 BASE = keccak256(abi.encodePacked("BASE"));
        bytes32 OPTIMISM = keccak256(abi.encodePacked("OPTIMISM"));
        bytes32 ENV = keccak256(abi.encodePacked(chain));
        // SETUP DEPLOYMENT VARIABLES
        address proxy = address(0);
        address keyring = address(0);
        if ( ENV == STAGING ) {
            proxy = PROXY_STAGING;
        } else if ( ENV == UAT ) {
            proxy = PROXY_UAT;
        } else if ( ENV == PROD ) {
            proxy = PROXY_PROD_MAINNET;
        } else if ( ENV == ARBITRUM ) {
            proxy = PROXY_PROD_ARBITRUM;
        } else if ( ENV == BASE ) {
            proxy = PROXY_PROD_BASE;
        } else if ( ENV == OPTIMISM ) {
            proxy = PROXY_PROD_OPTIMISM;
        } else {
            console.log("Invalid ENV");
            console.log(chain);
            return;
        }
        console.log("ENV: %s", chain);
        console.log("PROXY: %s", proxy);

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