// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Deploy} from "../../script/Deploy.s.sol";
import {AlwaysValidSignatureChecker} from "../../src/signatureCheckers/AlwaysValidSignatureChecker.sol";
import {EIP191SignatureChecker} from "../../src/signatureCheckers/EIP191SignatureChecker.sol";
import {RSASignatureChecker} from "../../src/signatureCheckers/RSASignatureChecker.sol";
import {IKeyringCore} from "../../src/interfaces/IKeyringCore.sol";

contract DeployTest is Test {
    Deploy deployer;

    string deployerPrivateKeyStr;

    function setDeployerPrivateKey() internal {
        uint256 deployerPrivateKey = 0xA11CE;
        deployerPrivateKeyStr = vm.toString(deployerPrivateKey);
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.deal(deployerAddress, 100 ether);
    }

    function setUp() public {
        deployer = new Deploy();
        setDeployerPrivateKey();
        vm.setEnv("PRIVATE_KEY", "");
        vm.setEnv("SIGNATURE_CHECKER_NAME", "");
        vm.setEnv("PROXY_ADDRESS", "");
    }

    function test_RevertOnMissingSignatureCheckerName() public {
        vm.skip(true, "Bug with env var in Foundry");
        vm.setEnv("PRIVATE_KEY", deployerPrivateKeyStr);
        vm.expectRevert("Invalid signature checker name: ");
        deployer.run();
    }

    function test_RevertOnInvalidSignatureCheckerName() public {
        vm.skip(true, "Bug with env var in Foundry");
        vm.setEnv("PRIVATE_KEY", deployerPrivateKeyStr);
        vm.setEnv("SIGNATURE_CHECKER_NAME", "InvalidChecker");

        vm.expectRevert("Invalid signature checker name: InvalidChecker");
        deployer.run();
    }

    function test_DeployNewProxy() public {
        vm.skip(true, "Bug with env var in Foundry");
        // Set environment variables
        vm.setEnv("PRIVATE_KEY", deployerPrivateKeyStr);
        vm.setEnv("SIGNATURE_CHECKER_NAME", "AlwaysValidSignatureChecker");
        // Don't set PROXY_ADDRESS to test new deployment

        // Run the deployment script
        IKeyringCore proxyAddress = deployer.run();

        // Verify the deployment
        assertTrue(address(proxyAddress) != address(0), "Proxy address should not be null");

        // Verify the signature checker is set
        assertTrue(address(proxyAddress.signatureChecker()) != address(0), "Signature checker should be set");
    }

    function test_DeployWithDifferentSignatureCheckers() public {
        vm.skip(true, "Bug with env var in Foundry");
        vm.setEnv("PRIVATE_KEY", deployerPrivateKeyStr);

        // Test with AlwaysValidSignatureChecker
        vm.setEnv("SIGNATURE_CHECKER_NAME", "AlwaysValidSignatureChecker");
        IKeyringCore keyringCore1 = deployer.run();
        assertTrue(address(keyringCore1) != address(0));
        assertTrue(address(keyringCore1.signatureChecker()) != address(0));

        // Test with EIP191SignatureChecker
        vm.setEnv("SIGNATURE_CHECKER_NAME", "EIP191SignatureChecker");
        IKeyringCore keyringCore2 = deployer.run();
        assertTrue(address(keyringCore2) != address(0));
        assertTrue(address(keyringCore2.signatureChecker()) != address(0));

        // Test with RSASignatureChecker
        vm.setEnv("SIGNATURE_CHECKER_NAME", "RSASignatureChecker");
        IKeyringCore keyringCore3 = deployer.run();
        assertTrue(address(keyringCore3) != address(0));
        assertTrue(address(keyringCore3.signatureChecker()) != address(0));
    }

    function test_UpgradeExistingProxy() public {
        vm.skip(true, "Bug with env var in Foundry");
        // First deploy a new proxy
        vm.setEnv("PRIVATE_KEY", deployerPrivateKeyStr);
        vm.setEnv("SIGNATURE_CHECKER_NAME", "AlwaysValidSignatureChecker");
        address proxyAddress = address(deployer.run());
        assertTrue(address(proxyAddress) != address(0));

        // Set the PROXY_ADDRESS environment variable
        vm.setEnv("PROXY_ADDRESS", vm.toString(proxyAddress));

        // Run the upgrade
        address upgradedProxyAddress = address(deployer.run());

        // Verify the upgrade
        assertEq(upgradedProxyAddress, proxyAddress, "Proxy address should remain the same");
    }

    function test_RevertOnUpgradeWithInvalidOwner() public {
        vm.skip(true, "Bug with env var in Foundry");
        uint256 maliciousPrivateKey = 0xB22DF;
        string memory maliciousAddressPrivateKeyStr = vm.toString(maliciousPrivateKey);
        address maliciousAddress = vm.addr(maliciousPrivateKey);
        vm.deal(maliciousAddress, 100 ether);
        vm.setEnv("PRIVATE_KEY", maliciousAddressPrivateKeyStr);
        vm.setEnv("SIGNATURE_CHECKER_NAME", "AlwaysValidSignatureChecker");
        address proxyAddress = address(deployer.run());
        assertTrue(address(proxyAddress) != address(0));

        vm.setEnv("PROXY_ADDRESS", vm.toString(proxyAddress));

        vm.expectRevert(bytes4(keccak256("InvalidInitialization()")));
        deployer.run();
    }
}
