// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockChainlinkAggregator is AggregatorV3Interface {
    
    int256 private price;
    uint8 constant decimals_ = 8;
    uint256 constant version_ = 1;
    string constant description_ = "Mock Chainlink Aggregator";

    constructor(int256 _initialPrice) {
        price = _initialPrice;
    }

    function decimals() external pure override returns (uint8) {
        return decimals_;
    }

    function description() external pure override returns (string memory) {
        return description_;
    }

    function version() external pure override returns (uint256) {
        return version_;
    }

    function latestRoundData() external view override returns (
        uint80 roundId, 
        int256 answer, 
        uint256 startedAt, 
        uint256 updatedAt, 
        uint80 answeredInRound
    ) {
        return (1, price, block.timestamp, block.timestamp, 1);
    }

    function getRoundData(uint80 /*_roundId*/) external view override returns (
        uint80 roundId, 
        int256 answer,
        uint256 startedAt, 
        uint256 updatedAt, 
        uint80 answeredInRound
    ) {
        return (1, price, block.timestamp, block.timestamp, 1);
    }

    function setPrice(int256 _price) public {
        price = _price;
    }
}
