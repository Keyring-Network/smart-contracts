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
        // Encoded Message: 0123456789abcdef0123456789abcdef012345670001e24060df4f70610703800000000000000000000000000de0b6b3a76400006578616d706c655f6261636b646f6f725f64617461
        // Key:       bf5f1afa62dda3a4184bfccaaf0efd4fec28aa13addbc5bb5a4c4fa7b21a9158d68d258e61278e84b0beb685b9d6408b88df36643f8e065444688a5f9d5aab0d48320e4c36b7766eee27d764e5d00296455c37557107603290df43991a344c8b8e26df06c6abd5f1eff0b3890ab3e7b08bf8aa59b30e28707679b7ae447f9671e599432427baae0c488252daf39673b8b2ac28e9e740030871f78aa55f7c334082f45878c5a3c2a926ae430ab34f8ec59291d6aee2555d77089af3880acb993b75d0e744757f4ec069d63cefa44456ba0746cd7a8c520d22671fa6311c88a9be3f1471fa489efa5a52e9e077f3cd455bbf530d94922daf92f3ad1a33b97abb93
        // Signature: bc1c1769cde42e7f699ed69f1b2af1bf2d44e92f80ede553a76835f69187037594c81f6f4894fb2da67ba5c1a626e051486ae32de6f4c529fdd2b6c0ff1dd03479c3ec715642ad4c7d432717acfd612e1547aa67df28a9bba91a5f7e4cde010b749526a19423fe5c6c3e176340607cdab13fe9c2ab03c584dcf62d49423a826e
        address tradingAddress = 0x0123456789abcDEF0123456789abCDef01234567;
        uint256 policyId = 123456;
        uint256 createBefore = 1625247600;
        uint256 validUntil = 1627849600;
        uint256 cost = 1000000000000000000;
        bytes memory backdoor = hex"6578616d706c655f6261636b646f6f725f64617461";
        bytes memory key = hex"c28aa13addbc5bb5a4c4fa7b21a9158d68d258e61278e84b0beb685b9d6408b88df36643f8e065444688a5f9d5aab0d48320e4c36b7766eee27d764e5d00296455c37557107603290df43991a344c8b8e26df06c6abd5f1eff0b3890ab3e7b08bf8aa59b30e28707679b7ae447f9671e599432427baae0c488252daf39673b8b";
        bytes memory signature = hex"502f5ac1ba587e3eaff95c62fe5c4e05fb1bf7243297b7b9c1459d83c1898545114a74fef5ea5b98641292cd167a680eb346c9d3384e0bffb929364091d8b73fad82a9f97550e11b8eaf1abf32347a8ebab5fc77480dae381828cf50ab066ca0b41f2ecd3b1228c25888d07db4d30c3dbe7a691d4d180a2a0856de32120824a8";
        uint256 gasBefore = gasleft();
        bool result = keyring.verify(tradingAddress, policyId, createBefore, validUntil, cost, key, signature, backdoor);
        uint256 gasAfter = gasleft();
        emit log_named_uint("Gas Used:", gasBefore - gasAfter);
        assertTrue(result);
    }
}
