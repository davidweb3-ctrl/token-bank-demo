# Token Bank Demo

这是一个基于 Foundry 的以太坊智能合约项目，实现了 ERC20 代币合约和代币银行功能。

## 项目结构

```
├── src/
│   ├── BaseERC20.sol      # ERC20 代币合约
│   └── TokenBank.sol      # 代币银行合约
├── test/
│   └── TokenBank.t.sol    # 测试文件
├── script/
│   └── Deploy.s.sol       # 部署脚本
└── foundry.toml           # Foundry 配置文件
```

## 合约功能

### BaseERC20 合约

实现了标准的 ERC20 代币功能：

- **代币信息**：
  - 名称：BaseERC20
  - 符号：BERC20
  - 小数位：18
  - 总供应量：100,000,000 tokens

- **核心功能**：
  - `balanceOf(address)`: 查询账户余额
  - `transfer(address, uint256)`: 转账功能
  - `approve(address, uint256)`: 授权功能
  - `allowance(address, address)`: 查询授权额度
  - `transferFrom(address, address, uint256)`: 代理转账

### TokenBank 合约

提供代币存取银行功能：

- `deposit(uint256)`: 存入代币到银行
- `withdraw(uint256)`: 从银行提取代币
- `getDeposits(address)`: 查询用户存款余额
- `getTotalBalance()`: 查询银行总余额

## 安全特性

1. **转账限制**：
   - 转账金额不能超过余额
   - 代理转账不能超过授权额度
   - 所有错误都有明确的错误信息

2. **存取安全**：
   - 存款前需要先授权银行合约
   - 提取金额不能超过存款余额
   - 使用 `require` 进行参数验证

## 使用说明

### 编译合约

```bash
forge build
```

### 运行测试

```bash
forge test
```

### 部署合约

```bash
forge script script/Deploy.s.sol --broadcast
```

## 测试覆盖

测试文件包含了完整的功能测试：

- ERC20 基础功能测试
- 转账边界条件测试
- 授权和代理转账测试
- 银行存取功能测试
- 多用户场景测试
- 错误处理测试

## 技术栈

- **Solidity**: ^0.8.19
- **Foundry**: 开发框架
- **Forge**: 编译和测试工具

## 许可证

MIT License