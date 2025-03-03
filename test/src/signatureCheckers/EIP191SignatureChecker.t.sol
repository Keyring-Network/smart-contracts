// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {EIP191SignatureChecker} from "../../../src/signatureCheckers/EIP191SignatureChecker.sol";
import {ISignatureChecker} from "../../../src/interfaces/ISignatureChecker.sol";
import {SignatureCheckerBaseTest} from "./SignatureCheckerBase.t.sol";

contract EIP191SignatureCheckerTest is SignatureCheckerBaseTest {
    function setUp() public override {
        super.setUp();
        signatureChecker = new EIP191SignatureChecker();
    }

    function test_VerifyEIP191Vectors() public view {
        verify("EIP191_vectors.json", true);
    }
}
