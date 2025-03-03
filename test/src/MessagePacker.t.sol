// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MessagePacker} from "../../src/MessagePacker.sol";

contract MessagePackerTest is Test {
    MessagePacker public messagePacker;
    
    function setUp() public {
        messagePacker = new MessagePacker();
    }

    function test_PackMessageWithAllParameters() view public {
        bytes memory packedMessage = messagePacker.packMessage(
            address(0x1234),
            1,
            1640991600,
            1 ether,
            hex"abcd"
        );

        assertEq(packedMessage, bytes(hex"00000000000000000000000000000000000012340000000100007a6961cf8b700000000000000000000000000de0b6b3a7640000abcd"));
    }
} 