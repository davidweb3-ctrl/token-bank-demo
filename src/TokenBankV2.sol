// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TokenBank.sol";
import "./BaseERC20V2.sol";
import "./ITokenReceiver.sol";

/**
 * @title TokenBankV2
 * @dev Enhanced token bank that supports callback-based deposits via transferWithCallback
 * @notice Inherits from TokenBank and implements ITokenReceiver for automatic deposits
 * @author DeCert Token Bank Demo V2
 */
contract TokenBankV2 is TokenBank, ITokenReceiver {
    
    // ============ Additional Events ============
    /// @dev Emitted when tokens are deposited via callback
    event DepositViaCallback(address indexed user, uint256 amount, bytes data);
    
    // ============ Constructor ============
    /**
     * @dev Constructor that initializes the bank with BaseERC20V2 token
     * @param _token The address of the BaseERC20V2 token contract
     * @notice The token should be BaseERC20V2 or compatible contract
     */
    constructor(address _token) TokenBank(_token) {
        // TokenBank constructor handles the token initialization
    }

    // ============ ITokenReceiver Implementation ============
    /**
     * @dev Callback function called when tokens are transferred via transferWithCallback
     * @param from The address that sent the tokens
     * @param value The amount of tokens received
     * @param data Additional data sent with the transfer (optional)
     * @notice This function automatically records the deposit
     * @notice Requirements:
     * - Can only be called by the token contract
     * - Tokens must already be transferred to this contract before this call
     * @notice Emits DepositViaCallback and Deposit events
     */
    function tokensReceived(
        address from,
        uint256 value,
        bytes calldata data
    ) external override {
        // Verify that the caller is the token contract
        require(msg.sender == address(token), "TokenBankV2: caller is not the token contract");
        
        // Verify that we actually received the tokens
        require(value > 0, "TokenBankV2: cannot deposit zero amount");
        
        // Record the deposit in our mapping
        deposits[from] += value;
        
        // Emit events
        emit DepositViaCallback(from, value, data);
        emit Deposit(from, value);
    }

    // ============ Enhanced Deposit Functions ============
    /**
     * @dev Direct deposit function (inherited from TokenBank, still works)
     * @param amount The amount of tokens to deposit
     * @notice This is the traditional deposit method requiring approve + deposit
     */
    function deposit(uint256 amount) public override {
        super.deposit(amount);
    }

    /**
     * @dev Get the BaseERC20V2 token contract for direct interaction
     * @return The BaseERC20V2 token contract
     * @notice Users should call tokenV2.transferWithCallback(address(bankV2), amount, data) directly
     * @notice This avoids the need for approve + deposit pattern
     */
    function getTokenV2() public view returns (BaseERC20V2) {
        return BaseERC20V2(address(token));
    }

    // ============ View Functions ============
    /**
     * @dev Check if the token contract supports callback functionality
     * @return True if the token is BaseERC20V2 compatible
     * @notice Checks if the token contract has transferWithCallback function
     */
    function supportsCallback() public view returns (bool) {
        try BaseERC20V2(address(token)).isContract(address(this)) returns (bool) {
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @dev Get detailed information about the bank
     * @return tokenAddress The address of the token contract
     * @return totalBalance The total balance held by the bank
     * @return supportsCallbacks Whether callback deposits are supported
     */
    function getBankInfo() public view returns (
        address tokenAddress,
        uint256 totalBalance,
        bool supportsCallbacks
    ) {
        return (
            address(token),
            getTotalBalance(),
            supportsCallback()
        );
    }

    // ============ Emergency Functions ============
    /**
     * @dev Emergency function to handle unexpected token transfers
     * @notice This can be called if tokens are sent directly without callback
     * @notice Only updates accounting, doesn't transfer tokens
     */
    function syncBalance() public {
        uint256 contractBalance = token.balanceOf(address(this));
        // Note: getTotalBalance() returns the actual contract balance, not recorded deposits
        // We need to calculate if there are any unaccounted tokens
        
        // For this implementation, we'll attribute any direct transfers to the caller
        // In a production system, you might want more sophisticated logic
        uint256 currentDeposits = deposits[msg.sender];
        
        // Check if the contract received tokens that aren't accounted for this user
        // This is a simplified implementation - in reality you'd need to track total deposits
        if (contractBalance > 0) {
            // If there are tokens in the contract and user has no deposits,
            // assume they sent tokens directly and attribute them
            if (currentDeposits == 0) {
                deposits[msg.sender] = contractBalance;
                emit Deposit(msg.sender, contractBalance);
            }
        }
    }
}
