// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICredentialCache {
    function checkCredential(address trader, uint32 admissionPolicyId) external view returns (bool);
}
