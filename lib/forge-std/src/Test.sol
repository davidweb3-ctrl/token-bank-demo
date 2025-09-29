// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vm.sol";

contract Test {
    Vm public constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function assertEq(uint256 a, uint256 b) internal pure {
        require(a == b, "assertion failed: a != b");
    }

    function assertEq(string memory a, string memory b) internal pure {
        require(keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)), "assertion failed: strings not equal");
    }

    function assertEq(address a, address b) internal pure {
        require(a == b, "assertion failed: addresses not equal");
    }

    function assertEq(bool a, bool b) internal pure {
        require(a == b, "assertion failed: bools not equal");
    }

    function assertTrue(bool condition) internal pure {
        require(condition, "assertion failed: condition is false");
    }

    function assertFalse(bool condition) internal pure {
        require(!condition, "assertion failed: condition is true");
    }
}

