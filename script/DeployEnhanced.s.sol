// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BaseERC20.sol";
import "../src/TokenBankEnhanced.sol";

contract DeployEnhancedScript is Script {
    function run() public {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy BaseERC20 token
        BaseERC20 token = new BaseERC20();
        console.log("BaseERC20 deployed at:", address(token));

        // Deploy TokenBankEnhanced
        TokenBankEnhanced bank = new TokenBankEnhanced(address(token));
        console.log("TokenBankEnhanced deployed at:", address(bank));
        console.log("Admin address:", bank.admin());

        // Stop broadcasting
        vm.stopBroadcast();

        // Log token information
        console.log("Token Name:", token.name());
        console.log("Token Symbol:", token.symbol());
        console.log("Token Decimals:", token.decimals());
        console.log("Token Total Supply:", token.totalSupply());
        console.log("Bank supports admin withdrawals: true");
    }
}
