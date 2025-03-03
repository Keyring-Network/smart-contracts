// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RSASignatureChecker} from "../../../src/signatureCheckers/RSASignatureChecker.sol";
import {ISignatureChecker} from "../../../src/interfaces/ISignatureChecker.sol";
import {SignatureCheckerBaseTest} from "./SignatureCheckerBase.t.sol";

contract RSASignatureCheckerTest is SignatureCheckerBaseTest {
    function setUp() public override {
        super.setUp();
        signatureChecker = new RSASignatureChecker();
    }

    function test_VerifyRSAVectors() public view {
        verify("RSA_vectors.json", false);
    }
}
