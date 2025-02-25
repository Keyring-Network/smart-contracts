// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../interfaces/IMessagePacker.sol";

contract MessagePacker is IMessagePacker {
    /**
     * @inheritdoc IMessagePacker
     */
    function packMessage(
        address tradingAddress,
        uint256 policyId,
        uint256 validUntil,
        uint256 cost,
        bytes calldata backdoor
    ) public view returns (bytes memory) {
        return abi.encodePacked(
            tradingAddress, uint8(0), uint24(policyId), block.chainid, uint32(validUntil), uint160(cost), backdoor
        );
    }
}
