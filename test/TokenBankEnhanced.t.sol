// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/BaseERC20.sol";
import "../src/TokenBankEnhanced.sol";

contract TokenBankEnhancedTest is Test {
    BaseERC20 public token;
    TokenBankEnhanced public bank;

    address public admin;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public user4 = address(0x4);
    address public user5 = address(0x5);

    uint256 public constant INITIAL_BALANCE = 10000 * 10 ** 18; // 10,000 tokens

    function setUp() public {
        // Deploy contracts
        token = new BaseERC20();
        bank = new TokenBankEnhanced(address(token));

        admin = address(this);

        // Transfer tokens to test users
        token.transfer(user1, INITIAL_BALANCE);
        token.transfer(user2, INITIAL_BALANCE);
        token.transfer(user3, INITIAL_BALANCE);
        token.transfer(user4, INITIAL_BALANCE);
        token.transfer(user5, INITIAL_BALANCE);
    }

    // ============ Test Case 1: 检查存款前后余额更新 ============

    function testDepositUpdatesBalance() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);

        // 记录存款前的余额
        uint256 userBalanceBefore = token.balanceOf(user1);
        uint256 bankBalanceBefore = bank.getTotalBalance();
        uint256 depositsBefore = bank.getDeposits(user1);

        // 授权并存款
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);

        // 记录存款后的余额
        uint256 userBalanceAfter = token.balanceOf(user1);
        uint256 bankBalanceAfter = bank.getTotalBalance();
        uint256 depositsAfter = bank.getDeposits(user1);

        // 断言检查
        assertEq(userBalanceBefore - userBalanceAfter, depositAmount);
        assertEq(bankBalanceAfter - bankBalanceBefore, depositAmount);
        assertEq(depositsAfter - depositsBefore, depositAmount);
        assertEq(depositsAfter, depositAmount);

        vm.stopPrank();
    }

    function testMultipleDepositsUpdateBalance() public {
        uint256 firstDeposit = 1000 * 10 ** 18;
        uint256 secondDeposit = 2000 * 10 ** 18;

        vm.startPrank(user1);

        // 第一次存款
        token.approve(address(bank), firstDeposit);
        bank.deposit(firstDeposit);
        assertEq(bank.getDeposits(user1), firstDeposit);

        // 第二次存款
        token.approve(address(bank), secondDeposit);
        bank.deposit(secondDeposit);
        assertEq(bank.getDeposits(user1), firstDeposit + secondDeposit);

        vm.stopPrank();
    }

    // ============ Test Case 2: 检查存款排名前3名 ============

    function testTop3WithOneUser() public {
        // 只有1个用户存款
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        (address[3] memory top3, uint256[3] memory amounts) = bank.getTop3Depositors();

        // 第1名应该是 user1
        assertEq(top3[0], user1);
        assertEq(amounts[0], depositAmount);

        // 第2、3名应该为空
        assertEq(top3[1], address(0));
        assertEq(amounts[1], 0);
        assertEq(top3[2], address(0));
        assertEq(amounts[2], 0);
    }

    function testTop3WithTwoUsers() public {
        // 2个用户存款，user1存得多
        uint256 user1Deposit = 2000 * 10 ** 18;
        uint256 user2Deposit = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), user1Deposit);
        bank.deposit(user1Deposit);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(bank), user2Deposit);
        bank.deposit(user2Deposit);
        vm.stopPrank();

        (address[3] memory top3, uint256[3] memory amounts) = bank.getTop3Depositors();

        // 排名应该是 user1, user2, empty
        assertEq(top3[0], user1);
        assertEq(amounts[0], user1Deposit);
        assertEq(top3[1], user2);
        assertEq(amounts[1], user2Deposit);
        assertEq(top3[2], address(0));
        assertEq(amounts[2], 0);
    }

    function testTop3WithThreeUsers() public {
        // 3个用户存款，按金额排序
        uint256 user1Deposit = 3000 * 10 ** 18;
        uint256 user2Deposit = 2000 * 10 ** 18;
        uint256 user3Deposit = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), user1Deposit);
        bank.deposit(user1Deposit);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(bank), user2Deposit);
        bank.deposit(user2Deposit);
        vm.stopPrank();

        vm.startPrank(user3);
        token.approve(address(bank), user3Deposit);
        bank.deposit(user3Deposit);
        vm.stopPrank();

        (address[3] memory top3, uint256[3] memory amounts) = bank.getTop3Depositors();

        // 排名应该是 user1, user2, user3
        assertEq(top3[0], user1);
        assertEq(amounts[0], user1Deposit);
        assertEq(top3[1], user2);
        assertEq(amounts[1], user2Deposit);
        assertEq(top3[2], user3);
        assertEq(amounts[2], user3Deposit);
    }

    function testTop3WithFourUsers() public {
        // 4个用户存款，只显示前3名
        uint256 user1Deposit = 4000 * 10 ** 18;
        uint256 user2Deposit = 3000 * 10 ** 18;
        uint256 user3Deposit = 2000 * 10 ** 18;
        uint256 user4Deposit = 1000 * 10 ** 18; // 这个应该被排除在前3之外

        vm.startPrank(user1);
        token.approve(address(bank), user1Deposit);
        bank.deposit(user1Deposit);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(bank), user2Deposit);
        bank.deposit(user2Deposit);
        vm.stopPrank();

        vm.startPrank(user3);
        token.approve(address(bank), user3Deposit);
        bank.deposit(user3Deposit);
        vm.stopPrank();

        vm.startPrank(user4);
        token.approve(address(bank), user4Deposit);
        bank.deposit(user4Deposit);
        vm.stopPrank();

        (address[3] memory top3, uint256[3] memory amounts) = bank.getTop3Depositors();

        // 排名应该是 user1, user2, user3 (user4被排除)
        assertEq(top3[0], user1);
        assertEq(amounts[0], user1Deposit);
        assertEq(top3[1], user2);
        assertEq(amounts[1], user2Deposit);
        assertEq(top3[2], user3);
        assertEq(amounts[2], user3Deposit);

        // user4不应该在前3名中
        assertTrue(top3[0] != user4 && top3[1] != user4 && top3[2] != user4);
    }

    // ============ Test Case 3: 同一用户多次存款的排名情况 ============

    function testTop3WithSameUserMultipleDeposits() public {
        // user1 多次存款，总额最多
        uint256 user1FirstDeposit = 1000 * 10 ** 18;
        uint256 user1SecondDeposit = 2000 * 10 ** 18;
        uint256 user2Deposit = 2500 * 10 ** 18;
        uint256 user3Deposit = 1500 * 10 ** 18;

        // user1 第一次存款
        vm.startPrank(user1);
        token.approve(address(bank), user1FirstDeposit);
        bank.deposit(user1FirstDeposit);
        vm.stopPrank();

        // user2 存款
        vm.startPrank(user2);
        token.approve(address(bank), user2Deposit);
        bank.deposit(user2Deposit);
        vm.stopPrank();

        // user3 存款
        vm.startPrank(user3);
        token.approve(address(bank), user3Deposit);
        bank.deposit(user3Deposit);
        vm.stopPrank();

        // user1 第二次存款（累计后应该是第一名）
        vm.startPrank(user1);
        token.approve(address(bank), user1SecondDeposit);
        bank.deposit(user1SecondDeposit);
        vm.stopPrank();

        (address[3] memory top3, uint256[3] memory amounts) = bank.getTop3Depositors();

        uint256 user1TotalDeposit = user1FirstDeposit + user1SecondDeposit;

        // user1 累计存款应该是第一名
        assertEq(top3[0], user1);
        assertEq(amounts[0], user1TotalDeposit);
        assertEq(top3[1], user2);
        assertEq(amounts[1], user2Deposit);
        assertEq(top3[2], user3);
        assertEq(amounts[2], user3Deposit);
    }

    function testTop3UpdatesAfterAdditionalDeposit() public {
        // 初始排名
        vm.startPrank(user1);
        token.approve(address(bank), 1000 * 10 ** 18);
        bank.deposit(1000 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(bank), 2000 * 10 ** 18);
        bank.deposit(2000 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user3);
        token.approve(address(bank), 1500 * 10 ** 18);
        bank.deposit(1500 * 10 ** 18);
        vm.stopPrank();

        // 检查初始排名: user2(2000), user3(1500), user1(1000)
        (address[3] memory top3Before, uint256[3] memory amountsBefore) = bank.getTop3Depositors();
        assertEq(top3Before[0], user2);

        // user1 追加存款，超过其他人
        vm.startPrank(user1);
        token.approve(address(bank), 3000 * 10 ** 18);
        bank.deposit(3000 * 10 ** 18); // user1 总计 4000
        vm.stopPrank();

        // 检查更新后排名: user1(4000), user2(2000), user3(1500)
        (address[3] memory top3After, uint256[3] memory amountsAfter) = bank.getTop3Depositors();
        assertEq(top3After[0], user1);
        assertEq(amountsAfter[0], 4000 * 10 ** 18);
        assertEq(top3After[1], user2);
        assertEq(top3After[2], user3);
    }

    // ============ Test Case 4: 只有管理员可以取款 ============

    function testOnlyAdminCanWithdraw() public {
        // 先让用户存款
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        // 管理员可以取款
        uint256 withdrawAmount = 500 * 10 ** 18;
        uint256 adminBalanceBefore = token.balanceOf(admin);

        bank.adminWithdraw(admin, withdrawAmount);

        uint256 adminBalanceAfter = token.balanceOf(admin);
        assertEq(adminBalanceAfter - adminBalanceBefore, withdrawAmount);
        assertEq(bank.getTotalBalance(), depositAmount - withdrawAmount);
    }

    function testNonAdminCannotWithdraw() public {
        // 先让用户存款
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        // 非管理员尝试取款应该失败
        vm.startPrank(user2);
        vm.expectRevert("Only admin can call this function");
        bank.adminWithdraw(user2, 500 * 10 ** 18);
        vm.stopPrank();
    }

    function testUserCannotWithdraw() public {
        // 即使是存款的用户自己也不能取款
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);

        // user1 尝试取款应该失败
        vm.expectRevert("Only admin can call this function");
        bank.adminWithdraw(user1, depositAmount);
        vm.stopPrank();
    }

    function testAdminCanWithdrawToAnyAddress() public {
        // 管理员可以将资金取到任意地址
        uint256 depositAmount = 2000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        // 管理员取款到 user5
        uint256 withdrawAmount = 1000 * 10 ** 18;
        uint256 user5BalanceBefore = token.balanceOf(user5);

        bank.adminWithdraw(user5, withdrawAmount);

        uint256 user5BalanceAfter = token.balanceOf(user5);
        assertEq(user5BalanceAfter - user5BalanceBefore, withdrawAmount);
    }

    function testAdminCannotWithdrawToZeroAddress() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        // 管理员不能取款到零地址
        vm.expectRevert("Cannot withdraw to zero address");
        bank.adminWithdraw(address(0), 500 * 10 ** 18);
    }

    function testAdminCannotWithdrawMoreThanBalance() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        // 管理员不能取出超过合约余额的金额
        vm.expectRevert("Insufficient contract balance");
        bank.adminWithdraw(admin, depositAmount + 1);
    }

    // ============ Additional Tests ============

    function testAdminIsSetCorrectly() public {
        assertEq(bank.admin(), admin);
    }

    function testDepositEmitsEvent() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);

        vm.expectEmit(true, false, false, true);
        emit Deposit(user1, depositAmount);
        bank.deposit(depositAmount);

        vm.stopPrank();
    }

    function testAdminWithdrawEmitsEvent() public {
        uint256 depositAmount = 1000 * 10 ** 18;

        vm.startPrank(user1);
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        vm.stopPrank();

        uint256 withdrawAmount = 500 * 10 ** 18;

        vm.expectEmit(true, true, false, true);
        emit AdminWithdraw(admin, admin, withdrawAmount);
        bank.adminWithdraw(admin, withdrawAmount);
    }

    function testGetDepositorCount() public {
        assertEq(bank.getDepositorCount(), 0);

        // user1 存款
        vm.startPrank(user1);
        token.approve(address(bank), 1000 * 10 ** 18);
        bank.deposit(1000 * 10 ** 18);
        vm.stopPrank();
        assertEq(bank.getDepositorCount(), 1);

        // user2 存款
        vm.startPrank(user2);
        token.approve(address(bank), 1000 * 10 ** 18);
        bank.deposit(1000 * 10 ** 18);
        vm.stopPrank();
        assertEq(bank.getDepositorCount(), 2);

        // user1 再次存款，不应该增加计数
        vm.startPrank(user1);
        token.approve(address(bank), 1000 * 10 ** 18);
        bank.deposit(1000 * 10 ** 18);
        vm.stopPrank();
        assertEq(bank.getDepositorCount(), 2);
    }

    // Events for testing
    event Deposit(address indexed user, uint256 amount);
    event AdminWithdraw(address indexed admin, address indexed to, uint256 amount);
}
