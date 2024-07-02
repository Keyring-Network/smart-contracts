// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/lib/RsaVerifyOptimized.sol";

contract RsaVerifyOptimizedTestRig is RsaVerifyOptimized {
    function verify(
        address tradingAddress,
        uint256 policyId,
        uint256 createBefore,
        uint256 validUntil,
        uint256 cost,
        bytes calldata key,
        bytes calldata signature,
        bytes calldata backdoor
    ) public view returns (bool) {
        return verifyAuthMessage(tradingAddress, policyId, createBefore, validUntil, cost, key, signature, backdoor);
    }
}

contract KeyringCoreV2UnsafeTest is Test {
    RsaVerifyOptimizedTestRig internal keyring;

    function setUp() public {
        keyring = new RsaVerifyOptimizedTestRig();
    }

    function testVerify() public {
        // Trading Address: 0x0123456789abcDEF0123456789abCDef01234567
        // Policy ID: 123456
        // Create Before: 1625247600
        // Valid Until: 1627849600
        // Cost: 1000000000000000000
        // Backdoor: 6578616d706c655f6261636b646f6f725f64617461
        // Encoded Message: 0123456789abcdef0123456789abcdef0123456701e24060df4f70610703800000000000000000000000000de0b6b3a76400006578616d706c655f6261636b646f6f725f64617461
        // Key: efe9bea006e5d2c7404daa0cce525fbbf0a782f43693df882faec03d7f1f6183a57cedf766107a3316ffdd7ae39d999e07a0c91a495b5852fac60a5ea20427a240f40183c1895a1520e8cab08da0074252c9ad27fc3eef5ddff300a584b9286d9556843f1e6ec3b3eb625af2e4fe5022c151888e6d40400e8796dc9728c7a6c5
        // Signature: a38c7dce2f90e42c6ec96972721e4dbc7bd23f6c9abd24004d2d56ab8f96599113a44f387555e277f8a2d95a70f1e308298f48462544d9ddbaff4c613eece2690bb7c7236f969f1f31d199ba9ee9299dc2dc7586dee78272dd474dbba7a5d8c37f6f306cdebf387a5cc0ceefef5de07604f8af2a611ec3667b1d159cc5c07675
        address tradingAddress = 0x0123456789abcDEF0123456789abCDef01234567;
        uint256 policyId = 123456;
        uint256 createBefore = 1625247600;
        uint256 validUntil = 1627849600;
        uint256 cost = 1000000000000000000;
        bytes memory backdoor = hex"6578616d706c655f6261636b646f6f725f64617461";
        bytes memory key = hex"efe9bea006e5d2c7404daa0cce525fbbf0a782f43693df882faec03d7f1f6183a57cedf766107a3316ffdd7ae39d999e07a0c91a495b5852fac60a5ea20427a240f40183c1895a1520e8cab08da0074252c9ad27fc3eef5ddff300a584b9286d9556843f1e6ec3b3eb625af2e4fe5022c151888e6d40400e8796dc9728c7a6c5";
        bytes memory signature = hex"a38c7dce2f90e42c6ec96972721e4dbc7bd23f6c9abd24004d2d56ab8f96599113a44f387555e277f8a2d95a70f1e308298f48462544d9ddbaff4c613eece2690bb7c7236f969f1f31d199ba9ee9299dc2dc7586dee78272dd474dbba7a5d8c37f6f306cdebf387a5cc0ceefef5de07604f8af2a611ec3667b1d159cc5c07675";
        uint256 gasBefore = gasleft();
        bool result = keyring.verify(tradingAddress, policyId, createBefore, validUntil, cost, key, signature, backdoor);
        uint256 gasAfter = gasleft();
        emit log_named_uint("Gas Used:", gasBefore - gasAfter);
        assertTrue(result);
    }
}
