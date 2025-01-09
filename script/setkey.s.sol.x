// XSPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// validFrom = 1726096915
// validTo = 1812496960
// key = 0xd5659e201603cf66ed3290f275d4caac9172db71b02d2415aae92effa3325c1ede5d9fac3872e278fc18c8a93537c20ebe89add92252c74bd695a47113cd2ccc954ec8190ad3a1c36ab63d360f1794c98bf6466617023c30a6d1f544e640ab7e638b59cd3e9826b469b74d4e3dd4e61b7197f82d467366e78430afbc5acaed03

/*
import {Script, console} from "forge-std/Script.sol";
import {CoreV2_3} from "../src/CoreV2_3.sol";
import "./common/deployments.sol";


contract setRSAKey is Script {

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
*/


