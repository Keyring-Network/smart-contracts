// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMessagePacker {
    function packAuthMessage(
        address tradingAddress,
        uint256 policyId,
        uint256 chainId,
        uint256 validUntil,
        uint256 cost,
        bytes calldata key,
        bytes calldata signature,
        bytes calldata backdoor
    ) external payable returns (bytes memory);
}
