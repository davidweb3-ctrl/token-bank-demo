// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseERC20.sol";

/**
 * @title TokenBank
 * @dev A contract that allows users to deposit and withdraw BaseERC20 tokens
 */
contract TokenBank {
    BaseERC20 public token;

    // Mapping to track deposits for each address
    mapping(address => uint256) public deposits;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @dev Constructor that sets the ERC20 token address
     * @param _token The address of the BaseERC20 token contract
     */
    constructor(address _token) {
        token = BaseERC20(_token);
    }

    /**
     * @dev Deposit tokens into the bank
     * @param amount The amount of tokens to deposit
     */
    function deposit(uint256 amount) public virtual {
        require(amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        // Transfer tokens from user to this contract
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update deposits mapping
        deposits[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev Withdraw tokens from the bank
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(deposits[msg.sender] >= amount, "Insufficient deposited balance");

        // Update deposits mapping
        deposits[msg.sender] -= amount;

        // Transfer tokens from this contract to user
        require(token.transfer(msg.sender, amount), "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Get the deposited balance of a user
     * @param user The address to check
     * @return The deposited balance
     */
    function getDeposits(address user) public view returns (uint256) {
        return deposits[user];
    }

    /**
     * @dev Get the total token balance of this contract
     * @return The total balance
     */
    function getTotalBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
