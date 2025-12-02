# Solidity 拍卖项目

## 项目结构

```
.
├── artifacts/              # 编译后的合约产物 (ABI, 字节码)
├── cache/                  # Hardhat 缓存，用于加速编译
├── contracts/              # 智能合约源代码文件
│   ├── Auction.sol         # 主拍卖合约 (可升级代理的实现)
│   ├── AuctionUpgradeable.sol # 可升级拍卖合约 (代理)
│   ├── MockERC20.sol       # 用于测试的模拟 ERC20 代币
│   ├── MockV3Aggregator.sol # 用于测试的模拟 Chainlink 价格聚合器
│   └── MyNFT.sol           # ERC721 NFT 合约
├── hardhat.config.cjs      # Hardhat 配置文件
├── package-lock.json       # 记录精确的依赖树
├── package.json            # 项目元数据和依赖项
├── scripts/                # 部署脚本
│   ├── deploy_auction.js   # 部署 Auction 合约的脚本
│   └── deploy_mynft.js     # 部署 MyNFT 合约的脚本
└── test/                   # 测试文件
    ├── Auction.js          # Auction 合约的测试
    └── MyNFT.js            # MyNFT 合约的测试
```

## 功能说明

### AuctionUpgradeable.sol
该合约实现了可升级的拍卖系统。主要功能包括：
- **拍卖创建**：允许用户为 NFT 创建新的拍卖，指定 NFT、起始价格（ETH 或 ERC20）和持续时间。
- **出价**：允许用户对活跃的拍卖进行出价。它支持 ETH 和 ERC20 出价。出价必须高于当前的最高出价。
- **退款**：当有新的更高出价时，自动退还给之前的最高出价者。
- **拍卖结束**：提供结束拍卖的机制。拍卖结束后，NFT 将转移给最高出价者，拍卖收益将转移给卖家。如果没有出价，NFT 将退还给卖家。
- **价格反馈**：与 Chainlink 价格反馈集成，将 ETH 和 ERC20 出价金额转换为美元，以进行一致的比较。
- **可升级性**：合约设计为使用 OpenZeppelin 的 UUPS 代理模式进行升级。

### MyNFT.sol
这是一个符合 ERC721 标准的 NFT 合约。主要功能包括：
- **铸造**：允许合约所有者铸造新的 NFT。
- **所有权**：标准的 ERC721 所有权和转移机制。
- **访问控制**：使用 OpenZeppelin 的 Ownable 合约进行基本访问控制，将铸造限制为合约所有者。

### MockERC20.sol
一个用于测试的简单模拟 ERC20 代币合约。它提供基本的 ERC20 功能，例如：
- **铸造**：允许创建者铸造新的代币。
- **转移**：标准的 ERC20 代币转移功能。

### MockV3Aggregator.sol
一个用于测试的模拟 Chainlink V3 聚合器合约。它模拟 Chainlink 价格反馈的行为，允许在测试环境中控制价格响应。

## 部署步骤

### 先决条件
- 已安装 Node.js 和 npm/yarn。
- 已设置 Hardhat 开发环境。

### 安装
1. 克隆仓库：
   ```bash
   git clone <repository_url>
   cd solidity_task3
   ```
2. 安装依赖项：
   ```bash
   npm install
   # 或
   yarn install
   ```

### 编译合约
要编译智能合约，运行：
```bash
npx hardhat compile
```

### 运行测试
要执行测试套件，运行：
```bash
npx hardhat test
```

### 部署到本地网络（例如 Hardhat Network）
1. 启动 Hardhat 网络（如果尚未运行）：
   ```bash
   npx hardhat node
   ```
2. 部署 MyNFT：
   ```bash
   npx hardhat run scripts/deploy_mynft.js --network localhost
   ```
3. 部署 Auction：
   ```bash
   npx hardhat run scripts/deploy_auction.js --network localhost
   ```
   *注意：如果 `MyNFT` 和 `MockERC20` 合约地址未自动链接，请确保更新 `scripts/deploy_auction.js`。*

### 部署到测试网或主网
1. 使用适当的网络详细信息（RPC URL、私钥）配置 `hardhat.config.cjs`。
2. 部署 MyNFT：
   ```bash
   npx hardhat run scripts/deploy_mynft.js --network <your_network_name>
   ```
3. 部署 Auction：
   ```bash
   npx hardhat run scripts/deploy_auction.js --network <your_network_name>
   ```
   *注意：将 `<your_network_name>` 替换为您配置的网络（例如 `sepolia`、`mainnet`）。*
