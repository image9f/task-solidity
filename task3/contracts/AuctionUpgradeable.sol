// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Auction.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// 可升级拍卖合约
contract AuctionUpgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable, Auction {
    /// @custom:oz-upgrades-unsafe-allow constructor
    // 构造函数，禁用初始化器，因为使用可升级合约模式
    constructor() {
        _disableInitializers();
    }

    // 初始化函数，用于设置合约所有者
    function initialize(
        address owner // 合约所有者地址
    ) initializer public {
        __Ownable_init(owner); // 初始化Ownable
        __UUPSUpgradeable_init(); // 初始化UUPSUpgradeable
        super.initialize(); // 调用父合约Auction的初始化函数
        // 如果需要，在此处初始化Auction特有的状态
    }

    // 授权升级函数，只有合约所有者才能调用
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}