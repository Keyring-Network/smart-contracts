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
            etherscanApiKey: vm.envOr("ETHERSCAN_API_KEY", emptyString),
            verifierUrl: vm.envOr("ETHERSCAN_BASE_API_URL", emptyString)
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
            Options memory upgradeOptions;

            // If etherscan api key and verifier url are set, download the source code and use it as a reference contract
            if (bytes(deployOptions.etherscanApiKey).length > 0 && bytes(deployOptions.verifierUrl).length > 0) {
                downloadSourceCode(proxyAddress, deployOptions.etherscanApiKey, deployOptions.verifierUrl);
                upgradeOptions.referenceContract = "downloaded_source_code.sol";
            } else {
                upgradeOptions.referenceContract = "KeyringCoreReferenceContract.sol";
            }
            vm.startBroadcast(deployOptions.deployerPrivateKey);
            Upgrades.upgradeProxy(
                proxyAddress, "KeyringCore.sol", abi.encodeCall(KeyringCore.reinitialize, ()), upgradeOptions
            );
            vm.stopBroadcast();
        }
        return KeyringCore(proxyAddress);
    }

    function downloadSourceCode(address contractAddress, string memory etherscanApiKey, string memory verifierUrl)
        public
    {
        // Construct the Etherscan API URL
        string memory apiUrl = string(
            abi.encodePacked(
                verifierUrl,
                "/api?module=contract&action=getsourcecode&address=",
                vm.toString(contractAddress),
                "&apikey=",
                etherscanApiKey
            )
        );

        // Make the API call
        string[] memory cmd = new string[](3);
        cmd[0] = "curl";
        cmd[1] = "-s";
        cmd[2] = apiUrl;
        bytes memory response = vm.ffi(cmd);
        string memory responseString = string(response);

        // Parse and output the flattened code
        console.log("Contract code at %s:", contractAddress);
        console.log(responseString);
    }
}
