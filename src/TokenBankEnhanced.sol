// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseERC20.sol";

/**
 * @title TokenBankEnhanced
 * @dev Enhanced token bank with deposit ranking and admin withdrawal features
 */
contract TokenBankEnhanced {
    BaseERC20 public token;
    address public admin;

    // Mapping to track deposits for each address
    mapping(address => uint256) public deposits;

    // Array to track all depositors
    address[] private depositors;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event AdminWithdraw(address indexed admin, address indexed to, uint256 amount);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /**
     * @dev Constructor that sets the ERC20 token address and admin
     * @param _token The address of the BaseERC20 token contract
     */
    constructor(address _token) {
        token = BaseERC20(_token);
        admin = msg.sender;
    }

    /**
     * @dev Deposit tokens into the bank
     * @param amount The amount of tokens to deposit
     */
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");

        // If this is the first deposit from this user, add to depositors array
        if (deposits[msg.sender] == 0) {
            depositors.push(msg.sender);
        }

        // Transfer tokens from user to this contract
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Update deposits mapping
        deposits[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev Admin withdraws tokens from the bank
     * @param to The address to send tokens to
     * @param amount The amount of tokens to withdraw
     */
    function adminWithdraw(address to, uint256 amount) public onlyAdmin {
        require(amount > 0, "Amount must be greater than 0");
        require(to != address(0), "Cannot withdraw to zero address");
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");

        // Transfer tokens from this contract to specified address
        require(token.transfer(to, amount), "Transfer failed");

        emit AdminWithdraw(admin, to, amount);
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

    /**
     * @dev Get top 3 depositors by deposit amount
     * @return top3 Array of top 3 depositor addresses
     * @return amounts Array of corresponding deposit amounts
     */
    function getTop3Depositors() public view returns (address[3] memory top3, uint256[3] memory amounts) {
        // Initialize arrays
        for (uint256 i = 0; i < 3; i++) {
            top3[i] = address(0);
            amounts[i] = 0;
        }

        // Find top 3 depositors
        for (uint256 i = 0; i < depositors.length; i++) {
            address depositor = depositors[i];
            uint256 amount = deposits[depositor];

            // Check if this depositor should be in top 3
            for (uint256 j = 0; j < 3; j++) {
                if (amount > amounts[j]) {
                    // Shift lower ranks down
                    for (uint256 k = 2; k > j; k--) {
                        top3[k] = top3[k - 1];
                        amounts[k] = amounts[k - 1];
                    }
                    // Insert current depositor
                    top3[j] = depositor;
                    amounts[j] = amount;
                    break;
                }
            }
        }

        return (top3, amounts);
    }

    /**
     * @dev Get the number of depositors
     * @return The number of unique depositors
     */
    function getDepositorCount() public view returns (uint256) {
        return depositors.length;
    }
}
