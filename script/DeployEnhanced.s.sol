// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/BaseERC20.sol";
import "../src/TokenBankEnhanced.sol";

contract DeployEnhancedScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy BaseERC20 token
        BaseERC20 token = new BaseERC20();
        console.log("BaseERC20 deployed at:", address(token));

        // Deploy TokenBankEnhanced
        TokenBankEnhanced bank = new TokenBankEnhanced(address(token));
        console.log("TokenBankEnhanced deployed at:", address(bank));
        console.log("Admin address:", bank.admin());

        vm.stopBroadcast();
    }
}
