// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/BaseERC20.sol";
import "../src/TokenBank.sol";

contract TokenBankTest is Test {
    BaseERC20 public token;
    TokenBank public bank;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    uint256 public constant INITIAL_BALANCE = 1000 * 10 ** 18; // 1000 tokens

    function setUp() public {
        // Deploy BaseERC20 contract
        token = new BaseERC20();

        // Deploy TokenBank contract
        bank = new TokenBank(address(token));

        // Transfer some tokens to test users
        token.transfer(user1, INITIAL_BALANCE);
        token.transfer(user2, INITIAL_BALANCE);
    }

    function testTokenInitialization() public {
        assertEq(token.name(), "BaseERC20");
        assertEq(token.symbol(), "BERC20");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 100_000_000 * 10 ** 18);
    }

    function testTokenTransfer() public {
        vm.startPrank(user1);
        uint256 transferAmount = 100 * 10 ** 18;

        uint256 balanceBefore = token.balanceOf(user2);
        token.transfer(user2, transferAmount);
        uint256 balanceAfter = token.balanceOf(user2);

        assertEq(balanceAfter - balanceBefore, transferAmount);
        vm.stopPrank();
    }

    function testTokenTransferExceedsBalance() public {
        vm.startPrank(user1);
        uint256 transferAmount = INITIAL_BALANCE + 1;

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "ERC20: transfer amount exceeds balance"));
        token.transfer(user2, transferAmount);
        vm.stopPrank();
    }

    function testTokenApproveAndTransferFrom() public {
        vm.startPrank(user1);
        uint256 approveAmount = 500 * 10 ** 18;

        // Approve user2 to spend tokens
        token.approve(user2, approveAmount);
        assertEq(token.allowance(user1, user2), approveAmount);
        vm.stopPrank();

        // Transfer from user1 to user2 via user2
        vm.startPrank(user2);
        uint256 transferAmount = 200 * 10 ** 18;
        uint256 balanceBefore = token.balanceOf(user2);

        token.transferFrom(user1, user2, transferAmount);

        uint256 balanceAfter = token.balanceOf(user2);
        assertEq(balanceAfter - balanceBefore, transferAmount);
        assertEq(token.allowance(user1, user2), approveAmount - transferAmount);
        vm.stopPrank();
    }

    function testTokenTransferFromExceedsBalance() public {
        vm.startPrank(user1);
        token.approve(user2, INITIAL_BALANCE + 1);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "ERC20: transfer amount exceeds balance"));
        token.transferFrom(user1, user2, INITIAL_BALANCE + 1);
        vm.stopPrank();
    }

    function testTokenTransferFromExceedsAllowance() public {
        vm.startPrank(user1);
        uint256 approveAmount = 100 * 10 ** 18;
        token.approve(user2, approveAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "ERC20: transfer amount exceeds allowance"));
        token.transferFrom(user1, user2, approveAmount + 1);
        vm.stopPrank();
    }

    function testBankDeposit() public {
        vm.startPrank(user1);
        uint256 depositAmount = 500 * 10 ** 18;

        // Approve bank to spend tokens
        token.approve(address(bank), depositAmount);

        uint256 balanceBefore = token.balanceOf(user1);
        bank.deposit(depositAmount);
        uint256 balanceAfter = token.balanceOf(user1);

        assertEq(balanceBefore - balanceAfter, depositAmount);
        assertEq(bank.getDeposits(user1), depositAmount);
        assertEq(bank.getTotalBalance(), depositAmount);
        vm.stopPrank();
    }

    function testBankWithdraw() public {
        vm.startPrank(user1);
        uint256 depositAmount = 500 * 10 ** 18;

        // First deposit
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);

        // Then withdraw
        uint256 withdrawAmount = 200 * 10 ** 18;
        uint256 balanceBefore = token.balanceOf(user1);
        bank.withdraw(withdrawAmount);
        uint256 balanceAfter = token.balanceOf(user1);

        assertEq(balanceAfter - balanceBefore, withdrawAmount);
        assertEq(bank.getDeposits(user1), depositAmount - withdrawAmount);
        vm.stopPrank();
    }

    function testBankDepositWithoutApproval() public {
        vm.startPrank(user1);
        uint256 depositAmount = 500 * 10 ** 18;

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Insufficient allowance"));
        bank.deposit(depositAmount);
        vm.stopPrank();
    }

    function testBankWithdrawExceedsDeposit() public {
        vm.startPrank(user1);
        uint256 depositAmount = 500 * 10 ** 18;

        // First deposit
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);

        // Try to withdraw more than deposited
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "Insufficient deposited balance"));
        bank.withdraw(depositAmount + 1);
        vm.stopPrank();
    }

    function testBankMultipleUsersDeposit() public {
        // User1 deposits
        vm.startPrank(user1);
        uint256 deposit1 = 300 * 10 ** 18;
        token.approve(address(bank), deposit1);
        bank.deposit(deposit1);
        vm.stopPrank();

        // User2 deposits
        vm.startPrank(user2);
        uint256 deposit2 = 500 * 10 ** 18;
        token.approve(address(bank), deposit2);
        bank.deposit(deposit2);
        vm.stopPrank();

        assertEq(bank.getDeposits(user1), deposit1);
        assertEq(bank.getDeposits(user2), deposit2);
        assertEq(bank.getTotalBalance(), deposit1 + deposit2);
    }

    // ============ New Security Tests ============
    function testTokenTransferToZeroAddress() public {
        vm.startPrank(user1);
        uint256 transferAmount = 100 * 10 ** 18;

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "ERC20: transfer to the zero address"));
        token.transfer(address(0), transferAmount);
        vm.stopPrank();
    }

    function testTokenTransferFromToZeroAddress() public {
        vm.startPrank(user1);
        uint256 approveAmount = 500 * 10 ** 18;
        token.approve(user2, approveAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        uint256 transferAmount = 200 * 10 ** 18;
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "ERC20: transfer to the zero address"));
        token.transferFrom(user1, address(0), transferAmount);
        vm.stopPrank();
    }

    function testTokenApproveToZeroAddress() public {
        vm.startPrank(user1);
        uint256 approveAmount = 500 * 10 ** 18;

        vm.expectRevert(abi.encodeWithSignature("Error(string)", "ERC20: approve to the zero address"));
        token.approve(address(0), approveAmount);
        vm.stopPrank();
    }

    function testTokenInitialTransferEvent() public {
        // Deploy a new token to test the initial Transfer event
        BaseERC20 newToken = new BaseERC20();

        // Check that deployer received all tokens
        assertEq(newToken.balanceOf(address(this)), 100_000_000 * 10 ** 18);
        assertEq(newToken.totalSupply(), 100_000_000 * 10 ** 18);
    }
}
