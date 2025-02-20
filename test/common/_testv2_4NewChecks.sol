// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IKeyringChecker} from "../../src/interfaces/IKeyringChecker.sol";
contract _testv2_4NewChecks is Test {
        address nonAdmin = address(0x123);
        bytes testKey = hex"abcd";
        
        //vm.warp(1704067200); // 01-01-2024 00:00:00

    function _testAll(address _c4) internal {
        
        IKeyringChecker c4 = IKeyringChecker(_c4);
        _testNormalSituation(c4);
        _testZeroCost(c4);
        _testMsgValueTooLow(c4);
        _testChainIdMismatch(c4);
    }
    // skip this test for now
    // using foundry syntax
    function _testNormalSituation(IKeyringChecker c4) internal {
        // @todo: remove this skip once the test is implemented
        vm.skip(true);

        uint256 chainId = block.chainid;
        //c4.registerKey(validFrom, validTo, testKey);
        uint256 validUntil = block.timestamp + 1 days;

        c4.createCredential{value: 1 ether}(nonAdmin, 1, chainId, validUntil, 1 ether, testKey, "", "");
        assertTrue(c4.checkCredential(1, nonAdmin));
    
    }

    function _testZeroCost(IKeyringChecker c4) internal {
        // @todo: remove this skip once the test is implemented
        vm.skip(true);
        //
    }
    function _testMsgValueTooLow(IKeyringChecker c4) internal {
        // @todo: remove this skip once the test is implemented
        vm.skip(true);
        //
    }
    function _testChainIdMismatch(IKeyringChecker c4) internal {
        vm.skip(true);
        //
    }
}
