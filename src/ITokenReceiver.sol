// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ITokenReceiver
 * @dev Interface for contracts that can receive tokens via transferWithCallback
 * @notice This interface defines the callback function that will be called 
 *         when tokens are transferred to a contract address using transferWithCallback
 */
interface ITokenReceiver {
    /**
     * @dev Called when tokens are transferred to this contract via transferWithCallback
     * @param from The address that sent the tokens
     * @param value The amount of tokens transferred
     * @param data Additional data sent with the transfer (can be empty)
     * @notice This function should handle the token reception logic
     * @notice It should revert if the transfer is not accepted
     */
    function tokensReceived(
        address from,
        uint256 value,
        bytes calldata data
    ) external;
}
