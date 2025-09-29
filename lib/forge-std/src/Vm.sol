// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Vm {
    function startPrank(address) external;
    function stopPrank() external;
    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;
    function expectEmit(bool, bool, bool, bool) external;
    function startBroadcast() external;
    function stopBroadcast() external;
}
