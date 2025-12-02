// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 模拟ERC20代币合约
contract MockERC20 is ERC20 {
    // 构造函数，初始化ERC20代币名称和符号，并铸造初始代币给部署者
    constructor() ERC20("MockERC20", "MERC20") {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // 铸造1,000,000个代币给部署者
    }

    // 铸造函数，允许铸造指定数量的代币给指定地址
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}