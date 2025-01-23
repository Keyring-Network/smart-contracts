// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/lib/EIP191Verify.sol";

contract EIP191VerifyTestRig is EIP191Verify {
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
    EIP191VerifyTestRig internal keyring;

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
        keyring = new EIP191VerifyTestRig();
    }

    function testVerify() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/vectors/secp256k1_vector.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        TestVectors memory testVectors = abi.decode(data, (TestVectors));
        uint256 i = 0;
        for (; i < testVectors.vectors.length; i++) {
            TestVector memory vector = testVectors.vectors[i];
            // THIS NEXT LINE IS BECAUSE WE HAVE TO PAD THE KEY TO 21 BYTES OR THE JSON PARSER GET ANGRY
            // SO WE TRIM IT BACK TO 20 BYTES
            bytes memory key = trimBytes(vector.key);
            bool result = keyring.verify(
                vector.tradingAddress,
                vector.policyId,
                vector.createBefore,
                vector.validUntil,
                vector.cost,
                key,
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
