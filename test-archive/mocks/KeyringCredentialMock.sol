// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract KeyringCredentialMock {
    mapping(uint32 => mapping(address => bool)) private walletCheck;

    function checkCredential(address trader, uint32 admissionPolicyId) external view returns (bool passed) {
        return walletCheck[admissionPolicyId][trader];
    }

    function set(address trader, uint256 admissionPolicyId, bool passed) external {
        walletCheck[uint32(admissionPolicyId)][trader] = passed;
    }
}
