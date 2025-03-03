// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console, VmSafe} from "forge-std/Script.sol";
import {KeyringCore} from "../src/KeyringCore.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";
import {IDeployOptions} from "../src/interfaces/IDeployOptions.sol";
import {Strings} from "@openzeppelin-contracts/utils/Strings.sol";
import {RSASignatureChecker} from "../src/signatureCheckers/RSASignatureChecker.sol";
import {EIP191SignatureChecker} from "../src/signatureCheckers/EIP191SignatureChecker.sol";
import {AlwaysValidSignatureChecker} from "../src/signatureCheckers/AlwaysValidSignatureChecker.sol";

contract Deploy is Script, IDeployOptions {
    using Strings for string;

    function run() external returns (KeyringCore) {
        DeployOptions memory deployOptions;
        string memory emptyString = "";
        deployOptions = DeployOptions({
            deployerPrivateKey: vm.envUint("PRIVATE_KEY"),
            signatureCheckerName: vm.envOr("SIGNATURE_CHECKER_NAME", emptyString),
            proxyAddress: vm.envOr("PROXY_ADDRESS", emptyString),
            referenceContract: vm.envOr("REFERENCE_CONTRACT", emptyString)
        });
        return deploy(deployOptions);
    }

    function deploy(DeployOptions memory deployOptions) public returns (KeyringCore) {
        address proxyAddress =
            bytes(deployOptions.proxyAddress).length > 0 ? vm.parseAddress(deployOptions.proxyAddress) : address(0);

        if (proxyAddress == address(0)) {
            address signatureCheckerAddress;
            vm.startBroadcast(deployOptions.deployerPrivateKey);

            if (deployOptions.signatureCheckerName.equal("RSASignatureChecker")) {
                signatureCheckerAddress = address(new RSASignatureChecker());
            } else if (deployOptions.signatureCheckerName.equal("AlwaysValidSignatureChecker")) {
                signatureCheckerAddress = address(new AlwaysValidSignatureChecker());
            } else if (deployOptions.signatureCheckerName.equal("EIP191SignatureChecker")) {
                signatureCheckerAddress = address(new EIP191SignatureChecker());
            } else {
                revert(string.concat("Invalid signature checker name: ", deployOptions.signatureCheckerName));
            }

            console.log("Deploying the KeyringCore contract proxy and implementation");
            proxyAddress = Upgrades.deployUUPSProxy(
                "KeyringCore.sol", abi.encodeCall(KeyringCore.initialize, signatureCheckerAddress)
            );
            vm.stopBroadcast();
        } else {
            console.log("Using existing proxy address:", proxyAddress);
            console.log("Upgrading the KeyringCore contract for the proxy");
            Options memory upgradeOptions;
            upgradeOptions.referenceContract = deployOptions.referenceContract;
            vm.startBroadcast(deployOptions.deployerPrivateKey);
            Upgrades.upgradeProxy(
                proxyAddress, "KeyringCore.sol", abi.encodeCall(KeyringCore.reinitialize, ()), upgradeOptions
            );
            vm.stopBroadcast();
        }
        return KeyringCore(proxyAddress);
    }
}
