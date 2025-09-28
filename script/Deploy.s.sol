// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BaseERC20.sol";
import "../src/TokenBank.sol";

contract DeployScript is Script {
    function run() public {
        // Start broadcasting transactions
        vm.startBroadcast();
        
        // Deploy BaseERC20 contract
        BaseERC20 token = new BaseERC20();
        console.log("BaseERC20 deployed at:", address(token));
        
        // Deploy TokenBank contract
        TokenBank bank = new TokenBank(address(token));
        console.log("TokenBank deployed at:", address(bank));
        
        // Stop broadcasting
        vm.stopBroadcast();
        
        // Log token information
        console.log("Token Name:", token.name());
        console.log("Token Symbol:", token.symbol());
        console.log("Token Decimals:", token.decimals());
        console.log("Token Total Supply:", token.totalSupply());
    }
}

