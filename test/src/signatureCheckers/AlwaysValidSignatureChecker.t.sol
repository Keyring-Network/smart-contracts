// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AlwaysValidSignatureChecker} from "../../../src/signatureCheckers/AlwaysValidSignatureChecker.sol";

contract AlwaysValidSignatureCheckerTest is Test {
    AlwaysValidSignatureChecker checker;

    function setUp() public {
        checker = new AlwaysValidSignatureChecker();
    }

    function test_Verify() public view {
        assertTrue(checker.checkSignature(address(0), 0, 0, 0, "", "", ""));
    }

    function test_Verify_InvalidSignature() public view {
        assertFalse(checker.checkSignature(address(0), 0, 0, 0, hex"dead", "", ""));
    }
}
