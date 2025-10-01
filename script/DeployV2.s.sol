// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BaseERC20V2.sol";
import "../src/TokenBankV2.sol";

contract DeployV2Script is Script {
    function run() public {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy BaseERC20V2 contract
        BaseERC20V2 tokenV2 = new BaseERC20V2();
        console.log("BaseERC20V2 deployed at:", address(tokenV2));

        // Deploy TokenBankV2 contract
        TokenBankV2 bankV2 = new TokenBankV2(address(tokenV2));
        console.log("TokenBankV2 deployed at:", address(bankV2));

        // Stop broadcasting
        vm.stopBroadcast();

        // Log token information
        console.log("Token Name:", tokenV2.name());
        console.log("Token Symbol:", tokenV2.symbol());
        console.log("Token Decimals:", tokenV2.decimals());
        console.log("Token Total Supply:", tokenV2.totalSupply());
        console.log("Bank supports callbacks:");
        console.log(bankV2.supportsCallback());
    }
}
