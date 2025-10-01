// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/BaseERC20V2.sol";
import "../src/TokenBankV2.sol";
import "../src/ITokenReceiver.sol";

contract TokenBankV2Test is Test {
    BaseERC20V2 public tokenV2;
    TokenBankV2 public bankV2;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    uint256 public constant INITIAL_BALANCE = 1000 * 10 ** 18; // 1000 tokens

    function setUp() public {
        // Deploy BaseERC20V2 contract
        tokenV2 = new BaseERC20V2();

        // Deploy TokenBankV2 contract
        bankV2 = new TokenBankV2(address(tokenV2));

        // Transfer some tokens to test users
        tokenV2.transfer(user1, INITIAL_BALANCE);
        tokenV2.transfer(user2, INITIAL_BALANCE);
    }

    // ============ Basic Functionality Tests ============
    function testTokenV2Initialization() public {
        assertEq(tokenV2.name(), "BaseERC20");
        assertEq(tokenV2.symbol(), "BERC20");
        assertEq(tokenV2.decimals(), 18);
        assertEq(tokenV2.totalSupply(), 100_000_000 * 10 ** 18);
    }

    function testDebugBalances() public {
        // Debug: check balances after setup
        uint256 deployerBalance = tokenV2.balanceOf(address(this));
        uint256 user1Balance = tokenV2.balanceOf(user1);
        uint256 user2Balance = tokenV2.balanceOf(user2);

        // These should pass if setup is correct
        assertEq(user1Balance, INITIAL_BALANCE);
        assertEq(user2Balance, INITIAL_BALANCE);

        // Check total supply accounting
        assertEq(deployerBalance + user1Balance + user2Balance, tokenV2.totalSupply());
    }

    function testBankV2Initialization() public {
        (address tokenAddr, uint256 totalBal, bool supportsCallbacks) = bankV2.getBankInfo();
        assertEq(tokenAddr, address(tokenV2));
        assertEq(totalBal, 0);
        assertTrue(supportsCallbacks);
    }

    // ============ TransferWithCallback Tests ============
    function testTransferWithCallbackToEOA() public {
        vm.startPrank(user1);
        uint256 transferAmount = 100 * 10 ** 18;
        bytes memory data = "test data";

        uint256 balanceBefore = tokenV2.balanceOf(user2);
        bool success = tokenV2.transferWithCallback(user2, transferAmount, data);
        uint256 balanceAfter = tokenV2.balanceOf(user2);

        assertTrue(success);
        assertEq(balanceAfter - balanceBefore, transferAmount);
        vm.stopPrank();
    }

    function testTransferWithCallbackToContract() public {
        vm.startPrank(user1);
        uint256 transferAmount = 500 * 10 ** 18;
        bytes memory data = "deposit via callback";

        uint256 userBalanceBefore = tokenV2.balanceOf(user1);
        uint256 bankBalanceBefore = tokenV2.balanceOf(address(bankV2));
        uint256 depositsBefore = bankV2.getDeposits(user1);

        bool success = tokenV2.transferWithCallback(address(bankV2), transferAmount, data);

        uint256 userBalanceAfter = tokenV2.balanceOf(user1);
        uint256 bankBalanceAfter = tokenV2.balanceOf(address(bankV2));
        uint256 depositsAfter = bankV2.getDeposits(user1);

        assertTrue(success);
        assertEq(userBalanceBefore - userBalanceAfter, transferAmount);
        assertEq(bankBalanceAfter - bankBalanceBefore, transferAmount);
        assertEq(depositsAfter - depositsBefore, transferAmount);
        vm.stopPrank();
    }

    function testTransferFromWithCallback() public {
        vm.startPrank(user1);
        uint256 approveAmount = 500 * 10 ** 18;
        uint256 transferAmount = 300 * 10 ** 18;

        // Approve user2 to spend tokens
        tokenV2.approve(user2, approveAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        bytes memory data = "transferFrom with callback";

        uint256 user1BalanceBefore = tokenV2.balanceOf(user1);
        uint256 bankBalanceBefore = tokenV2.balanceOf(address(bankV2));
        uint256 depositsBefore = bankV2.getDeposits(user1);

        bool success = tokenV2.transferFromWithCallback(user1, address(bankV2), transferAmount, data);

        uint256 user1BalanceAfter = tokenV2.balanceOf(user1);
        uint256 bankBalanceAfter = tokenV2.balanceOf(address(bankV2));
        uint256 depositsAfter = bankV2.getDeposits(user1);

        assertTrue(success);
        assertEq(user1BalanceBefore - user1BalanceAfter, transferAmount);
        assertEq(bankBalanceAfter - bankBalanceBefore, transferAmount);
        assertEq(depositsAfter - depositsBefore, transferAmount);
        assertEq(tokenV2.allowance(user1, user2), approveAmount - transferAmount);
        vm.stopPrank();
    }

    // ============ TokenBankV2 Specific Tests ============
    function testDepositWithCallback() public {
        vm.startPrank(user1);
        uint256 depositAmount = 400 * 10 ** 18;
        bytes memory data = "direct deposit with callback";

        uint256 userBalanceBefore = tokenV2.balanceOf(user1);
        uint256 bankBalanceBefore = tokenV2.balanceOf(address(bankV2));
        uint256 depositsBefore = bankV2.getDeposits(user1);

        // User directly calls transferWithCallback on the token
        bool success = tokenV2.transferWithCallback(address(bankV2), depositAmount, data);

        uint256 userBalanceAfter = tokenV2.balanceOf(user1);
        uint256 bankBalanceAfter = tokenV2.balanceOf(address(bankV2));
        uint256 depositsAfter = bankV2.getDeposits(user1);

        assertTrue(success);
        assertEq(userBalanceBefore - userBalanceAfter, depositAmount);
        assertEq(bankBalanceAfter - bankBalanceBefore, depositAmount);
        assertEq(depositsAfter - depositsBefore, depositAmount);
        vm.stopPrank();
    }

    function testDepositWithCallbackNoData() public {
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10 ** 18;

        uint256 userBalanceBefore = tokenV2.balanceOf(user1);
        uint256 depositsBefore = bankV2.getDeposits(user1);

        // User directly calls transferWithCallback with empty data
        bool success = tokenV2.transferWithCallback(address(bankV2), depositAmount, "");

        uint256 userBalanceAfter = tokenV2.balanceOf(user1);
        uint256 depositsAfter = bankV2.getDeposits(user1);

        assertTrue(success);
        assertEq(userBalanceBefore - userBalanceAfter, depositAmount);
        assertEq(depositsAfter - depositsBefore, depositAmount);
        vm.stopPrank();
    }

    function testTraditionalDepositStillWorks() public {
        vm.startPrank(user1);
        uint256 depositAmount = 300 * 10 ** 18;

        // Traditional approve + deposit method
        tokenV2.approve(address(bankV2), depositAmount);

        uint256 userBalanceBefore = tokenV2.balanceOf(user1);
        uint256 depositsBefore = bankV2.getDeposits(user1);

        bankV2.deposit(depositAmount);

        uint256 userBalanceAfter = tokenV2.balanceOf(user1);
        uint256 depositsAfter = bankV2.getDeposits(user1);

        assertEq(userBalanceBefore - userBalanceAfter, depositAmount);
        assertEq(depositsAfter - depositsBefore, depositAmount);
        vm.stopPrank();
    }

    function testWithdrawAfterCallbackDeposit() public {
        vm.startPrank(user1);
        uint256 depositAmount = 500 * 10 ** 18;
        uint256 withdrawAmount = 200 * 10 ** 18;

        // Deposit via callback
        tokenV2.transferWithCallback(address(bankV2), depositAmount, "");

        // Withdraw
        uint256 userBalanceBefore = tokenV2.balanceOf(user1);
        uint256 depositsBefore = bankV2.getDeposits(user1);

        bankV2.withdraw(withdrawAmount);

        uint256 userBalanceAfter = tokenV2.balanceOf(user1);
        uint256 depositsAfter = bankV2.getDeposits(user1);

        assertEq(userBalanceAfter - userBalanceBefore, withdrawAmount);
        assertEq(depositsBefore - depositsAfter, withdrawAmount);
        vm.stopPrank();
    }

    // ============ Error Handling Tests ============
    function testTransferWithCallbackExceedsBalance() public {
        vm.startPrank(user1);
        uint256 transferAmount = INITIAL_BALANCE + 1;

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "ERC20: transfer amount exceeds balance"));
        tokenV2.transferWithCallback(user2, transferAmount, "");
        vm.stopPrank();
    }

    function testTransferWithCallbackToZeroAddress() public {
        vm.startPrank(user1);
        uint256 transferAmount = 100 * 10 ** 18;

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "ERC20: transfer to the zero address"));
        tokenV2.transferWithCallback(address(0), transferAmount, "");
        vm.stopPrank();
    }

    function testGetTokenV2() public {
        BaseERC20V2 tokenFromBank = bankV2.getTokenV2();
        assertEq(address(tokenFromBank), address(tokenV2));
    }

    function testTokensReceivedOnlyFromTokenContract() public {
        vm.startPrank(user1);

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "TokenBankV2: caller is not the token contract"));
        bankV2.tokensReceived(user1, 100 * 10 ** 18, "");
        vm.stopPrank();
    }

    // ============ Utility Tests ============
    function testIsContract() public {
        assertTrue(tokenV2.isContract(address(bankV2)));
        assertFalse(tokenV2.isContract(user1));
        assertFalse(tokenV2.isContract(user2));
    }

    function testSyncBalance() public {
        vm.startPrank(user1);
        uint256 transferAmount = 100 * 10 ** 18;

        // Transfer tokens directly without callback (simulate accidental transfer)
        tokenV2.transfer(address(bankV2), transferAmount);

        // Initially, deposits should be 0 for user1
        assertEq(bankV2.getDeposits(user1), 0);

        // Sync balance should attribute unaccounted tokens to caller
        bankV2.syncBalance();

        // Now user1 should have the deposited amount recorded
        assertEq(bankV2.getDeposits(user1), transferAmount);
        vm.stopPrank();
    }

    // ============ Event Tests ============
    function testTransferWithCallbackEvents() public {
        vm.startPrank(user1);
        uint256 transferAmount = 100 * 10 ** 18;
        bytes memory data = "test data";

        // Expect Transfer event
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, user2, transferAmount);

        // Expect TransferWithCallback event
        vm.expectEmit(true, true, false, true);
        emit TransferWithCallback(user1, user2, transferAmount, data);

        tokenV2.transferWithCallback(user2, transferAmount, data);
        vm.stopPrank();
    }

    function testDepositViaCallbackEvents() public {
        vm.startPrank(user1);
        uint256 depositAmount = 200 * 10 ** 18;
        bytes memory data = "deposit test";

        // Expect DepositViaCallback event
        vm.expectEmit(true, false, false, true);
        emit DepositViaCallback(user1, depositAmount, data);

        // Expect Deposit event
        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, depositAmount);

        tokenV2.transferWithCallback(address(bankV2), depositAmount, data);
        vm.stopPrank();
    }

    // Define events for testing
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferWithCallback(address indexed from, address indexed to, uint256 value, bytes data);
    event DepositViaCallback(address indexed user, uint256 amount, bytes data);
    event Deposit(address indexed user, uint256 amount);
}
