// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IKeyringCore} from "../../src/interfaces/IKeyringCore.sol";
import {Deploy} from "../../script/Deploy.s.sol";

abstract contract KeyringCoreBaseTest is Test {
    IKeyringCore public keyringCore;
    address public admin = address(this);
    address public nonAdmin = address(0x2);

    function setUp() virtual public {
        uint256 deployerPrivateKey = 0xA11CE;
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.deal(deployerAddress, 100 ether);

        // Set environment variables for deployment
        vm.setEnv("PRIVATE_KEY", vm.toString(deployerPrivateKey));
        vm.setEnv("SIGNATURE_CHECKER_NAME", "AlwaysValidSignatureChecker");
    
        keyringCore = (new Deploy()).run();
        vm.prank(deployerAddress);
        keyringCore.setAdmin(address(this));
    }

}
