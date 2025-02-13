// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

// LEAVE THESE VALUES ALONE EVEN IF THEY DO NOT EXIST IN ALL ENVS. THEY MUCT BE PRESENT FOR THE SCRIPT TO WORK
address constant KEYRING_CREDENTIALS_STAGING = 0xC29377e0B9b6297F3Ac60C6bd16F679FF600284d;
address constant KEYRING_CREDENTIALS_UAT = 0xda53684332841eB49f58378171FaE15B04Cd019F;
address constant KEYRING_CREDENTIALS_PROD = 0x8a16F136121FD53B5c72c3414b42299f972c9c67;

// ANY NEW PROXY ADDRESS SHOULD BE ADDED HERE
address constant PROXY_STAGING = 0x0b33fE66FF4Fa1B9784403c0b2315530735A6AEE;
address constant PROXY_UAT = 0x6fB4880678bFf1792eBF1C3FDdc16E4fbF4ad043;
address constant PROXY_PROD_MAINNET = 0xD18d17791f2071Bf3C855bA770420a9EdEa0728d;
address constant PROXY_PROD_ARBITRUM = 0x88e097C960aD0239B4eEC6E8C5B4f74f898eFdA3;
address constant PROXY_PROD_BASE = 0x88e097C960aD0239B4eEC6E8C5B4f74f898eFdA3;
address constant PROXY_PROD_OPTIMISM = 0x88e097C960aD0239B4eEC6E8C5B4f74f898eFdA3;
address constant PROXY_PROD_AVALANCHE = 0x88e097C960aD0239B4eEC6E8C5B4f74f898eFdA3;
address constant PROXY_PROD_ZKSYNC = 0x617534538624ae12AC8F5A12cbC22491FED7D63D;

// THIS MAY BE IGNORED - IT WAS DEPLOYED FOR TESTING THE TRACER SYSTEM
address constant TRIGGERTRACER_UAT = 0x2fac2892E7452c394639133D4406a519267359E2;

// THIS MUST BE UPDATED FOR NEW ENVS TO INCLUDE THE NEW ENV NAME
// THIS IS USED TO DETERMINE WHICH PROXY TO USE IN SCRIPTS
bytes32 constant STAGING = keccak256(abi.encodePacked("STAGING"));
bytes32 constant UAT = keccak256(abi.encodePacked("UAT"));
bytes32 constant PROD = keccak256(abi.encodePacked("PROD"));
bytes32 constant ARBITRUM = keccak256(abi.encodePacked("ARBITRUM"));
bytes32 constant BASE = keccak256(abi.encodePacked("BASE"));
bytes32 constant OPTIMISM = keccak256(abi.encodePacked("OPTIMISM"));
bytes32 constant AVALANCHE = keccak256(abi.encodePacked("AVALANCHE"));
bytes32 constant ZKSYNC = keccak256(abi.encodePacked("ZKSYNC"));

abstract contract Tooling is Script {

    function loadPrivk() public view returns (uint256, address) {
        // LOAD ENV VARIABLES
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        require(deployerPrivateKey != 0, "PRIVATE_KEY not set");

        address deployerAddress = vm.addr(deployerPrivateKey);
        require(deployerAddress != address(0), "Invalid PRIVATE_KEY");
        console.log("DEPLOYER: %s", deployerAddress);
        return (deployerPrivateKey, deployerAddress);
    }
    
    // THIS FUNCTION MUST BE UPDATED FOR NEW ENVS TO INCLUDE THE NEW ENV NAME
    function params(string memory chain) public view returns (address, address) {
        bytes32 ENV = keccak256(abi.encodePacked(chain));
        address proxy = address(0);
        address keyring = address(0);
        keyring = KEYRING_CREDENTIALS_PROD;
        // SETUP DEPLOYMENT VARIABLES
        if ( ENV == STAGING ) {
            proxy = PROXY_STAGING;
            keyring = KEYRING_CREDENTIALS_STAGING;
        } else if ( ENV == UAT ) {
            proxy = PROXY_UAT;
            keyring = KEYRING_CREDENTIALS_UAT;
        } else if ( ENV == PROD ) {
            proxy = PROXY_PROD_MAINNET;
        } else if ( ENV == ARBITRUM ) {
            proxy = PROXY_PROD_ARBITRUM;
        } else if ( ENV == BASE ) {
            proxy = PROXY_PROD_BASE;
        } else if ( ENV == OPTIMISM ) {
            proxy = PROXY_PROD_OPTIMISM;
        } else if ( ENV == AVALANCHE ) {
            proxy = PROXY_PROD_AVALANCHE;
        } else if ( ENV == ZKSYNC ) {
            proxy = PROXY_PROD_ZKSYNC;
        } else {
            console.log("Invalid ENV");
            console.log(chain);
            revert("Invalid ENV");
        }
        console.log("ENV: %s", chain);
        console.log("PROXY: %s", proxy);
        console.log("KEYRING: %s", keyring);

        return (proxy, keyring);
    }
}