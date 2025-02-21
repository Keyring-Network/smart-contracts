// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/lib/RsaVerifyOptimized.sol";

import "../src/CoreV2_3_zksync.sol";
import "../src/CoreV2_4_zksync.sol";
import "../src/CoreV2.sol";
import "../src/CoreV2_2.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract KeyringCoreV2UnsafeTest is Test {
    // MUST BE IN ALPHABETICAL ORDER OR JSON WILL NOT PARSE!
    struct TestVector {
        bytes backdoor;
        uint256 chainId;
        uint256 cost;
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
        vm.chainId(1625247600);
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/vectors/secp256k1_vector.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        TestVectors memory testVectors = abi.decode(data, (TestVectors));
        uint256 i = 0;
        for (; i < testVectors.vectors.length; i++) {
            TestVector memory vector = testVectors.vectors[i];

            // Deploy V2
            address core = address(new CoreV2(address(0)));
            ERC1967Proxy proxy = new ERC1967Proxy(address(core), abi.encodeCall(CoreV2.initialize, address(this)));
            CoreV2_3_zksync keyring = CoreV2_3_zksync(address(proxy));

            // Upgrade to V2_2
            core = address(new CoreV2_2(address(0)));
            keyring.upgradeToAndCall(address(core), abi.encodeWithSelector(CoreV2_2.initialize.selector));

            // Upgrade to V2_3
            core = address(new CoreV2_3_zksync());
            keyring.upgradeToAndCall(address(core), abi.encodeWithSelector(CoreV2_3_zksync.initialize.selector));

            // Upgrade to V2_4
            core = address(new CoreV2_4_zksync());
            keyring.upgradeToAndCall(address(core), abi.encodeWithSelector(CoreV2_4_zksync.initialize.selector));

            // Attacker can not upgrade
            address attacker = makeAddr("attacker");
            vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, attacker));
            vm.prank(attacker);
            keyring.upgradeToAndCall(address(core), abi.encodeWithSelector(CoreV2_4_zksync.initialize.selector));

            // Can not initialize twice
            vm.expectRevert(InvalidInitialization.selector);
            keyring.initialize();

            // Can not initialize implementation
            vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(this)));
            CoreV2_4_zksync(core).initialize();
            bytes memory key = trimBytes(vector.key);

            keyring.registerKey(block.chainid, type(uint32).max, key);

            if (!vector.expected) vm.expectRevert();
            keyring.createCredential{value: vector.cost}(
                vector.tradingAddress,
                vector.policyId,
                vector.chainId,
                vector.validUntil,
                vector.cost,
                key,
                vector.signature,
                vector.backdoor
            );
        }
        assertTrue(i == testVectors.vectors.length);
        console.log("All tests passed", i);
    }

    function trimBytes(bytes memory vector) public pure returns (bytes memory) {
        require(vector.length == 21, "Input must be 21 bytes long");

        bytes memory vectorNew = new bytes(20);

        assembly {
            // Get a pointer to the start of `vectorNew`'s data
            let dest := add(vectorNew, 0x20)
            // Get a pointer to the start of `vector`'s data + 1 bytes
            let src := add(vector, 0x21)
            // Copy 20 bytes from `src` to `dest`
            mstore(dest, mload(src))
            mstore(add(dest, 0x10), mload(add(src, 0x10)))
        }

        return vectorNew;
    }
}