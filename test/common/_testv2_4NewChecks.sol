// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ICoreV2Base} from "../../src/interfaces/ICoreV2Base.sol";
contract _testv2_4NewChecks is Test {

    function _testAll(address _c4) internal {
        ICoreV2Base c4 = ICoreV2Base(_c4);
        _testZeroCost(c4);
        _testMsgValueTooLow(c4);
        _testChainIdMismatch(c4);
    }

    function _testZeroCost(ICoreV2Base c4) internal {
        //
    }
    function _testMsgValueTooLow(ICoreV2Base c4) internal {
        //
    }
    function _testChainIdMismatch(ICoreV2Base c4) internal {
        //
    }
}
