// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// 模拟Chainlink V3聚合器合约
contract MockV3Aggregator is AggregatorV3Interface {
    uint8 private _decimals; // 价格的小数位数
    int256 private _answer; // 模拟的价格答案

    // 构造函数，初始化小数位数和初始价格
    constructor(uint8 decimals_, int256 initialAnswer_) {
        _decimals = decimals_;
        _answer = initialAnswer_;
    }

    // 返回价格的小数位数
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    // 返回描述信息
    function description() external pure override returns (string memory) {
        return "MockV3Aggregator";
    }

    // 返回版本号
    function version() external pure override returns (uint256) {
        return 1;
    }

    // 获取指定轮次的数据
    function getRoundData(uint80 _roundId) external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (_roundId, _answer, block.timestamp, block.timestamp, _roundId);
    }

    // 获取最新轮次的数据
    function latestRoundData() external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (1, _answer, block.timestamp, block.timestamp, 1);
    }

    // 更新模拟价格
    function updateAnswer(int256 newAnswer) public {
        _answer = newAnswer;
    }
}