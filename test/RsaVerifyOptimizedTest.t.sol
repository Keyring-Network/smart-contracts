// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/lib/RsaVerifyOptimized.sol";

contract RsaVerifyOptimizedTestRig is RsaVerifyOptimized {
    function verify(
        address tradingAddress,
        uint256 policyId,
        uint256 createBefore,
        uint256 validUntil,
        uint256 cost,
        bytes calldata key,
        bytes calldata signature,
        bytes calldata backdoor
    ) public view returns (bool) {
        return verifyAuthMessage(tradingAddress, policyId, createBefore, validUntil, cost, key, signature, backdoor);
    }
}

contract KeyringCoreV2UnsafeTest is Test {
    RsaVerifyOptimizedTestRig internal keyring;

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

    function setUp() public {
        keyring = new RsaVerifyOptimizedTestRig();
    }

    function testVerify() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/vectors/rsa_vector.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        TestVectors memory testVectors = abi.decode(data, (TestVectors));
        uint256 i = 0;
        for (; i < testVectors.vectors.length; i++) {
            TestVector memory vector = testVectors.vectors[i];
            bool result = keyring.verify(
                vector.tradingAddress,
                vector.policyId,
                vector.createBefore,
                vector.validUntil,
                vector.cost,
                vector.key,
                vector.signature,
                vector.backdoor
            );
            if (result != vector.expected) {
                console.log("Failed test", i);
                console.log("Expected", vector.expected);
                console.log("Got", result);
            }
            assertTrue(result == vector.expected);
        }
        assertTrue(i == testVectors.vectors.length);
        console.log("All tests passed", i);
    }
}
