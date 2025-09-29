// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title BaseERC20
 * @dev Implementation of the ERC20 token standard with enhanced security features
 * @author DeCert Token Bank Demo
 */
contract BaseERC20 {
    // ============ Token Constants ============
    /// @dev Token name constant
    string private constant TOKEN_NAME = "BaseERC20";
    /// @dev Token symbol constant  
    string private constant TOKEN_SYMBOL = "BERC20";
    /// @dev Token decimals constant (18 is standard for most ERC20 tokens)
    uint8 private constant TOKEN_DECIMALS = 18;
    /// @dev Total supply constant: 100 million tokens with 18 decimals
    uint256 private constant TOKEN_TOTAL_SUPPLY = 100000000 * (10 ** uint256(TOKEN_DECIMALS));
    
    // ============ Public Token Metadata ============
    /// @dev Token name (publicly accessible)
    string public name; 
    /// @dev Token symbol (publicly accessible)
    string public symbol; 
    /// @dev Number of decimals (publicly accessible)
    uint8 public decimals; 
    /// @dev Total token supply (publicly accessible)
    uint256 public totalSupply; 

    // ============ Storage Mappings ============
    /// @dev Mapping from account addresses to their token balances
    mapping (address => uint256) internal balances; 
    /// @dev Mapping from token owner to spender allowances
    /// @notice allowances[owner][spender] = amount
    mapping (address => mapping (address => uint256)) internal allowances; 

    // ============ Events ============
    /// @dev Emitted when tokens are transferred from one account to another
    event Transfer(address indexed from, address indexed to, uint256 value);
    /// @dev Emitted when an allowance is set by a call to approve
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ============ Constructor ============
    /**
     * @dev Contract constructor that initializes the token
     * @notice Sets up token metadata and assigns all tokens to the deployer
     * - Initializes name, symbol, decimals, and totalSupply from constants
     * - Assigns the entire token supply to the contract deployer (msg.sender)
     * - Emits initial Transfer event from zero address to deployer
     */
    constructor() {
        // Initialize token metadata from constants
        name = TOKEN_NAME;
        symbol = TOKEN_SYMBOL;
        decimals = TOKEN_DECIMALS;
        totalSupply = TOKEN_TOTAL_SUPPLY;

        // Assign all tokens to the contract deployer
        balances[msg.sender] = TOKEN_TOTAL_SUPPLY;
        
        // Emit Transfer event for initial token creation
        emit Transfer(address(0), msg.sender, TOKEN_TOTAL_SUPPLY);
    }

    // ============ View Functions ============
    /**
     * @dev Returns the token balance of a specific account
     * @param _owner The address to query the balance of
     * @return balance The number of tokens owned by the specified address
     * @notice This function is part of the ERC20 standard
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Returns the remaining number of tokens that spender is allowed to spend on behalf of owner
     * @param _owner The address that owns the tokens
     * @param _spender The address that is allowed to spend the tokens
     * @return remaining The number of tokens that spender is still allowed to spend
     * @notice This function is part of the ERC20 standard
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        return allowances[_owner][_spender];
    }

    // ============ Transfer Functions ============
    /**
     * @dev Transfers tokens from the caller's account to another account
     * @param _to The address to transfer tokens to
     * @param _value The amount of tokens to transfer
     * @return success True if the transfer was successful
     * @notice Requirements:
     * - `_to` cannot be the zero address
     * - The caller must have a balance of at least `_value` tokens
     * @notice Emits a Transfer event
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // Check that sender has sufficient balance
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        // Prevent transfers to zero address (token burning should be explicit)
        require(_to != address(0), "ERC20: transfer to the zero address");
        
        // Execute the transfer
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        // Emit Transfer event
        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    /**
     * @dev Transfers tokens from one account to another using allowance mechanism
     * @param _from The address to transfer tokens from
     * @param _to The address to transfer tokens to  
     * @param _value The amount of tokens to transfer
     * @return success True if the transfer was successful
     * @notice Requirements:
     * - `_from` and `_to` cannot be the zero address
     * - `_from` must have a balance of at least `_value` tokens
     * - The caller must have allowance for at least `_value` tokens of `_from`'s tokens
     * @notice Emits a Transfer event and updates the allowance
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // Check that source account has sufficient balance
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        // Check that caller has sufficient allowance
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
        // Prevent transfers to zero address
        require(_to != address(0), "ERC20: transfer to the zero address");

        // Execute the transfer
        balances[_from] -= _value;
        balances[_to] += _value;
        // Reduce the allowance
        allowances[_from][msg.sender] -= _value;
        
        // Emit Transfer event
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    // ============ Approval Functions ============
    /**
     * @dev Sets the allowance of a spender over the caller's tokens
     * @param _spender The address that will be allowed to spend tokens
     * @param _value The amount of tokens that can be spent
     * @return success True if the approval was successful
     * @notice Requirements:
     * - `_spender` cannot be the zero address
     * @notice Emits an Approval event
     * @notice Be aware of the ERC20 approve race condition. Consider using increaseAllowance/decreaseAllowance instead
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // Prevent approval to zero address
        require(_spender != address(0), "ERC20: approve to the zero address");

        // Set the allowance
        allowances[msg.sender][_spender] = _value;

        // Emit Approval event
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }
}

