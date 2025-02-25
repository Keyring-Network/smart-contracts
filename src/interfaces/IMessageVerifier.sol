// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMessageVerifier {
    function verifyAuthMessage(
        address tradingAddress,
        uint256 policyId,
        uint256 chainId,
        uint256 validUntil,
        uint256 cost,
        bytes calldata key,
        bytes calldata signature,
        bytes calldata backdoor
    ) external view returns (bool);
}
