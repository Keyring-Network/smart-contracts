// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/lib/RsaVerifyOptimized.sol";

import "../src/CoreV2_3.sol";
import "../src/CoreV2_4.sol";
import "../src/CoreV2.sol";
import "../src/CoreV2_2.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract KeyringCoreV2UnsafeTest is Test {
    // MUST BE IN ALPHABETICAL ORDER OR JSON WILL NOT PARSE!
    struct TestVector {
        bytes backdoor;
        uint256 cost;
        uint256 createBefore;
        bool expected;
        bytes key;
        uint256 policyId;
        bytes signature;
        address tradingAddress;
        uint256 validUntil;
    }

    struct TestVectors {
        TestVector[] vectors;
    }

    error OwnableUnauthorizedAccount(address account);
    error InvalidInitialization();

    function testFullVerify() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/vectors/rsa_vector.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        TestVectors memory testVectors = abi.decode(data, (TestVectors));
        uint256 i = 0;
        for (; i < testVectors.vectors.length; i++) {
            TestVector memory vector = testVectors.vectors[i];

            // Deploy V2
            address core = address(new CoreV2(address(0)));
            ERC1967Proxy proxy = new ERC1967Proxy(address(core), abi.encodeCall(CoreV2.initialize, address(this)));
            CoreV2_3 keyring = CoreV2_3(address(proxy));

            // Upgrade to V2_2
            core = address(new CoreV2_2(address(0)));
            keyring.upgradeToAndCall(address(core), abi.encodeWithSelector(CoreV2_2.initialize.selector));

            // Upgrade to V2_3
            core = address(new CoreV2_3());
            keyring.upgradeToAndCall(address(core), abi.encodeWithSelector(CoreV2_3.initialize.selector));

            // Upgrade to V2_4
            core = address(new CoreV2_4());
            keyring.upgradeToAndCall(address(core), abi.encodeWithSelector(CoreV2_4.initialize.selector));

            // Attacker can not upgrade
            address attacker = makeAddr("attacker");
            vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, attacker));
            vm.prank(attacker);
            keyring.upgradeToAndCall(address(core), abi.encodeWithSelector(CoreV2_4.initialize.selector));

            // Can not initialize twice
            vm.expectRevert(InvalidInitialization.selector);
            keyring.initialize();

            // Can not initialize implementation
            vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(this)));
            CoreV2_3(core).initialize();

            keyring.registerKey(0, type(uint32).max, vector.key);

            if (!vector.expected) vm.expectRevert();
            keyring.createCredential{value: vector.cost}(
                vector.tradingAddress,
                vector.policyId,
                vector.createBefore,
                vector.validUntil,
                vector.cost,
                vector.key,
                vector.signature,
                vector.backdoor
            );
        }
        assertTrue(i == testVectors.vectors.length);
        console.log("All tests passed", i);
    }
}