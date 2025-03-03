// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console, VmSafe} from "forge-std/Script.sol";
import {KeyringCore} from "../src/KeyringCore.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {Strings} from "@openzeppelin-contracts/utils/Strings.sol";
import {RSASignatureChecker} from "../src/messageVerifiers/RSASignatureChecker.sol";
import {EIP191SignatureChecker} from "../src/messageVerifiers/EIP191SignatureChecker.sol";
import {AlwaysValidSignatureChecker} from "../src/messageVerifiers/AlwaysValidSignatureChecker.sol";

contract Deploy is Script {
    using Strings for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory proxyAddressStr;
        try vm.envString("PROXY_ADDRESS") returns (string memory addr) {
            proxyAddressStr = addr;
        } catch {
            proxyAddressStr = "";
        }
        address proxyAddress = bytes(proxyAddressStr).length > 0 ? vm.parseAddress(proxyAddressStr) : address(0);

        if (proxyAddress == address(0)) {
            vm.startBroadcast(deployerPrivateKey);

            console.log("Deploying the Signature Checker", vm.envString("SIGNATURE_CHECKER_NAME"));
            address signatureCheckerAddress;
            string memory signatureCheckerName = vm.envString("SIGNATURE_CHECKER_NAME");
            if (signatureCheckerName.equal("RSASignatureChecker")) {
                signatureCheckerAddress = address(new RSASignatureChecker());
            } else if (signatureCheckerName.equal("EIP191SignatureChecker")) {
                signatureCheckerAddress = address(new EIP191SignatureChecker());
            } else if (signatureCheckerName.equal("AlwaysValidSignatureChecker")) {
                signatureCheckerAddress = address(new AlwaysValidSignatureChecker());
            } else {
                revert("Invalid signature checker name");
            }

            console.log("Deploying the KeyringCore contract proxy and implementation");
            proxyAddress = Upgrades.deployUUPSProxy(
                "KeyringCore.sol", abi.encodeCall(KeyringCore.initialize, signatureCheckerAddress)
            );
            vm.stopBroadcast();
            if (vm.isContext(VmSafe.ForgeContext.ScriptBroadcast)) {
                console.log("Deployment is actually broadcasted, proxy address:", proxyAddress);
            } else {
                console.log("Deployment is not broadcasted, skipping (add --broadcast to the command to deploy)");
            }
        } else {
            console.log("Using existing proxy address:", proxyAddress);
            console.log("Upgrading the KeyringCore contract for the proxy");
            vm.startBroadcast(deployerPrivateKey);
            Upgrades.upgradeProxy(proxyAddress, "KeyringCore.sol", abi.encodeCall(KeyringCore.reinitialize, ()));
            vm.stopBroadcast();
        }
    }
}
