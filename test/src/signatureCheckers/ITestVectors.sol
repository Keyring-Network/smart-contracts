// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITestVectors {
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
}
