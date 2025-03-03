// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Deploy} from "../../script/Deploy.s.sol";
import {AlwaysValidSignatureChecker} from "../../src/messageVerifiers/AlwaysValidSignatureChecker.sol";
import {EIP191SignatureChecker} from "../../src/messageVerifiers/EIP191SignatureChecker.sol";
import {RSASignatureChecker} from "../../src/messageVerifiers/RSASignatureChecker.sol";
import {IKeyringCore} from "../../src/interfaces/IKeyringCore.sol";

contract DeployTest is Test {
    Deploy deployer;
    uint256 deployerPrivateKey;
    address deployerAddress;

    function setUp() public {
        deployerPrivateKey = 0xA11CE;
        deployerAddress = vm.addr(deployerPrivateKey);
        vm.deal(deployerAddress, 100 ether);
        deployer = new Deploy();
    }

    function test_DeployNewProxy() public {
        // Set environment variables
        vm.setEnv("PRIVATE_KEY", vm.toString(deployerPrivateKey));
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
        
        vm.setEnv("PRIVATE_KEY", vm.toString(deployerPrivateKey));

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
        // First deploy a new proxy
        vm.setEnv("PRIVATE_KEY", vm.toString(deployerPrivateKey));
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

    function test_RevertOnInvalidSignatureChecker() public {
        
        vm.setEnv("PRIVATE_KEY", vm.toString(deployerPrivateKey));
        vm.setEnv("SIGNATURE_CHECKER_NAME", "InvalidChecker");

        vm.expectRevert("Invalid signature checker name");
        deployer.run();
    }

    function test_RevertOnMissingSignatureCheckerName() public {
        vm.setEnv("PRIVATE_KEY", vm.toString(deployerPrivateKey));
        // Don't set SIGNATURE_CHECKER_NAME to test missing env var

        vm.expectRevert("SIGNATURE_CHECKER_NAME environment variable not set");
        deployer.run();
    }

    function test_RevertOnUpgradeWithInvalidOwner() public {
        // todo: fix this test
        vm.skip(true);
        vm.setEnv("PRIVATE_KEY", vm.toString(deployerPrivateKey));
        vm.setEnv("SIGNATURE_CHECKER_NAME", "AlwaysValidSignatureChecker");
        address proxyAddress = address(deployer.run());
        assertTrue(address(proxyAddress) != address(0));

        vm.setEnv("PROXY_ADDRESS", vm.toString(proxyAddress));
        
        address maliciousAddress = address(0x5);
        vm.prank(maliciousAddress);
        vm.expectRevert("Ownable: new owner is the zero address");
        deployer.run();
    }
}
