// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseERC20.sol";
import "./ITokenReceiver.sol";

/**
 * @title BaseERC20V2
 * @dev Extended ERC20 token with callback functionality for contract transfers
 * @notice Inherits from BaseERC20 and adds transferWithCallback function
 * @author DeCert Token Bank Demo V2
 */
contract BaseERC20V2 is BaseERC20 {
    // ============ Events ============
    /// @dev Emitted when tokens are transferred with callback to a contract
    event TransferWithCallback(address indexed from, address indexed to, uint256 value, bytes data);

    // ============ Hook Transfer Functions ============
    /**
     * @dev Transfers tokens and calls tokensReceived on the recipient if it's a contract
     * @param _to The address to transfer tokens to
     * @param _value The amount of tokens to transfer
     * @param _data Additional data to pass to the recipient contract
     * @return success True if the transfer was successful
     * @notice Requirements:
     * - Same as regular transfer function
     * - If `_to` is a contract, it must implement ITokenReceiver.tokensReceived
     * - The tokensReceived call must not revert
     * @notice Emits Transfer and TransferWithCallback events
     */
    function transferWithCallback(address _to, uint256 _value, bytes calldata _data) public returns (bool success) {
        // First perform the standard transfer
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        require(_to != address(0), "ERC20: transfer to the zero address");

        // Execute the transfer
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        // Emit standard Transfer event
        emit Transfer(msg.sender, _to, _value);

        // Check if recipient is a contract and call tokensReceived if it is
        if (_isContract(_to)) {
            try ITokenReceiver(_to).tokensReceived(msg.sender, _value, _data) {
                // Callback succeeded
            } catch {
                // Revert the transfer if callback fails
                revert("ERC20V2: tokensReceived callback failed");
            }
        }

        // Emit callback-specific event
        emit TransferWithCallback(msg.sender, _to, _value, _data);

        return true;
    }

    /**
     * @dev Transfers tokens from one address to another with callback functionality
     * @param _from The address to transfer tokens from
     * @param _to The address to transfer tokens to
     * @param _value The amount of tokens to transfer
     * @param _data Additional data to pass to the recipient contract
     * @return success True if the transfer was successful
     * @notice Requirements:
     * - Same as regular transferFrom function
     * - If `_to` is a contract, it must implement ITokenReceiver.tokensReceived
     * - The tokensReceived call must not revert
     * @notice Emits Transfer and TransferWithCallback events
     */
    function transferFromWithCallback(address _from, address _to, uint256 _value, bytes calldata _data)
        public
        returns (bool success)
    {
        // Check allowance and balances
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
        require(_to != address(0), "ERC20: transfer to the zero address");

        // Execute the transfer
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        // Emit standard Transfer event
        emit Transfer(_from, _to, _value);

        // Check if recipient is a contract and call tokensReceived if it is
        if (_isContract(_to)) {
            try ITokenReceiver(_to).tokensReceived(_from, _value, _data) {
                // Callback succeeded
            } catch {
                // Revert the transfer if callback fails
                revert("ERC20V2: tokensReceived callback failed");
            }
        }

        // Emit callback-specific event
        emit TransferWithCallback(_from, _to, _value, _data);

        return true;
    }

    // ============ Internal Helper Functions ============
    /**
     * @dev Checks if an address is a contract
     * @param _addr The address to check
     * @return True if the address is a contract, false otherwise
     * @notice Uses extcodesize to determine if address is a contract
     * @notice Returns false for EOA (Externally Owned Accounts)
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    // ============ View Functions ============
    /**
     * @dev Returns true if an address is a contract
     * @param _addr The address to check
     * @return True if the address is a contract
     * @notice Public version of _isContract for external queries
     */
    function isContract(address _addr) public view returns (bool) {
        return _isContract(_addr);
    }
}
