// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ISignatureChecker} from "../../../src/interfaces/ISignatureChecker.sol";
import {ITestVectors} from "./ITestVectors.sol";

abstract contract SignatureCheckerBaseTest is Test, ITestVectors {
    ISignatureChecker signatureChecker;

    function setUp() public virtual {
        vm.chainId(1625247600);
    }

    function verify(string memory fixturesFileName, bool mustStrimBytes) public view {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/fixtures/", fixturesFileName);
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        TestVectors memory testVectors = abi.decode(data, (TestVectors));
        uint256 i = 0;
        for (; i < testVectors.vectors.length; i++) {
            TestVector memory vector = testVectors.vectors[i];
            bytes memory key;
            if (mustStrimBytes) {
                // THIS NEXT LINE IS BECAUSE WE HAVE TO PAD THE KEY TO 21 BYTES OR THE JSON PARSER GET ANGRY
                // SO WE TRIM IT BACK TO 20 BYTES
                key = trimBytes(vector.key);
            } else {
                key = vector.key;
            }
            bool result = signatureChecker.checkSignature(
                vector.tradingAddress,
                vector.policyId,
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
