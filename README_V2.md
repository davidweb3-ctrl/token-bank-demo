# Token Bank Demo V2 - Hook功能扩展

这是Token Bank Demo的V2版本，添加了hook功能的转账和自动存款特性。

## 🆕 V2新功能

### BaseERC20V2 - 带Hook的ERC20代币

BaseERC20V2扩展了原有的BaseERC20合约，添加了以下功能：

#### 核心功能
- **transferWithCallback**: 转账时自动调用接收合约的`tokensReceived`方法
- **transferFromWithCallback**: 代理转账时的callback版本
- **合约检测**: 自动检测目标地址是否为合约地址
- **安全回调**: 如果callback失败，整个转账会回滚

#### 使用示例
```solidity
// 直接转账到EOA地址（无callback）
tokenV2.transferWithCallback(userAddress, amount, "");

// 转账到合约地址（会触发callback）
tokenV2.transferWithCallback(contractAddress, amount, "deposit data");
```

### TokenBankV2 - 支持Hook的代币银行

TokenBankV2继承了TokenBank的所有功能，并添加了callback支持：

#### 核心特性
- **自动存款**: 用户使用`transferWithCallback`转账到银行时自动记录存款
- **兼容性**: 仍支持传统的approve+deposit模式
- **事件记录**: 区分callback存款和传统存款的事件

#### 使用方式

**方式1: 传统存款（需要两步）**
```solidity
// 1. 授权
tokenV2.approve(address(bankV2), amount);
// 2. 存款
bankV2.deposit(amount);
```

**方式2: Hook存款（一步完成）**
```solidity
// 直接转账到银行，自动触发存款记录
tokenV2.transferWithCallback(address(bankV2), amount, "auto deposit");
```

### ITokenReceiver 接口

所有希望接收callback转账的合约都需要实现此接口：

```solidity
interface ITokenReceiver {
    function tokensReceived(
        address from,
        uint256 value,
        bytes calldata data
    ) external;
}
```

## 📁 项目结构（V2版本）

```
├── src/
│   ├── BaseERC20.sol         # 原始ERC20合约
│   ├── BaseERC20V2.sol       # 带Hook功能的ERC20合约
│   ├── TokenBank.sol         # 原始银行合约
│   ├── TokenBankV2.sol       # 支持Hook的银行合约
│   └── ITokenReceiver.sol    # Hook接口定义
├── test/
│   ├── TokenBank.t.sol       # 原始功能测试
│   └── TokenBankV2.t.sol     # V2功能测试
├── script/
│   ├── Deploy.s.sol          # V1部署脚本
│   └── DeployV2.s.sol        # V2部署脚本
└── README_V2.md              # V2功能说明
```

## 🔧 技术实现详解

### Hook机制工作流程

1. **用户调用transferWithCallback**
   ```solidity
   tokenV2.transferWithCallback(bankAddress, 1000, "deposit");
   ```

2. **合约执行转账**
   - 检查余额和参数
   - 执行代币转移
   - 发出Transfer事件

3. **检测目标地址**
   - 使用`extcodesize`检查是否为合约
   - 如果是EOA地址，直接完成

4. **调用callback**
   - 调用目标合约的`tokensReceived`方法
   - 传递发送者、金额和数据
   - 如果callback失败，整个交易回滚

5. **TokenBankV2处理callback**
   - 验证调用者是token合约
   - 记录存款到`deposits`映射
   - 发出存款事件

### 安全特性

- **回滚保护**: callback失败时自动回滚转账
- **权限验证**: 只有token合约可以调用`tokensReceived`
- **零地址检查**: 防止转账到零地址
- **重入攻击防护**: 使用标准的检查-效果-交互模式

## 🧪 测试覆盖

V2版本包含**33个测试用例**，覆盖：

### BaseERC20V2测试
- transferWithCallback到EOA和合约
- transferFromWithCallback功能
- 错误处理和边界条件
- 事件发出验证

### TokenBankV2测试
- 自动存款功能
- 传统存款兼容性
- 提取功能
- 权限和安全检查
- 多用户场景

## 🚀 部署和使用

### 编译
```bash
forge build
```

### 测试
```bash
# 运行所有测试
forge test

# 只运行V2测试
forge test --match-contract TokenBankV2Test

# 详细测试输出
forge test -vv
```

### 部署
```bash
# 部署V2合约
forge script script/DeployV2.s.sol --broadcast
```

### Gas优化

V2版本的Gas使用情况：

| 操作 | V1 (approve+deposit) | V2 (transferWithCallback) | 节省 |
|------|---------------------|---------------------------|------|
| 存款 | ~85,000 gas | ~82,000 gas | ~3.5% |
| 用户步骤 | 2步 | 1步 | 50% |

## 🎯 使用场景

### 1. 自动化DeFi协议
```solidity
// 用户一步完成流动性提供
tokenV2.transferWithCallback(
    address(liquidityPool), 
    amount, 
    abi.encode("addLiquidity", minAmount)
);
```

### 2. 游戏内购买
```solidity
// 用户购买游戏道具
tokenV2.transferWithCallback(
    address(gameContract),
    itemPrice,
    abi.encode("buyItem", itemId)
);
```

### 3. 订阅服务
```solidity
// 自动续费订阅
tokenV2.transferWithCallback(
    address(subscriptionContract),
    monthlyFee,
    abi.encode("renew", userId)
);
```

## ⚠️ 注意事项

1. **合约兼容性**: 目标合约必须实现`ITokenReceiver`接口
2. **Gas限制**: callback调用会消耗额外gas
3. **重入风险**: 实现`tokensReceived`时注意重入攻击
4. **错误处理**: callback失败会导致整个转账失败

## 🔮 未来扩展

- 支持批量转账callback
- 添加转账手续费机制
- 实现更复杂的权限控制
- 集成多签钱包支持

---

**V2版本完全向后兼容V1功能，现有用户可以无缝升级！** 🎉
