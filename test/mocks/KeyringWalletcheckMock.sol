
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract KeyringWalletcheckMock {

    mapping(uint32 => mapping(address => bool)) private walletCheck;

    function checkWallet(
        address observer, 
        address wallet,
        uint32 admissionPolicyId
    ) external returns (bool passed) {
        passed = true;
    }

    function set(
            address trader,
            uint32 admissionPolicyId,
            bool passed
        ) external {
            walletCheck[admissionPolicyId][trader] = passed;
        }
}