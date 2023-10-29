// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// Import OpenZeppelin's Pausable and ownable contract
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract ConditionalOrder is Pausable, Ownable {

    AggregatorV3Interface internal priceFeed;

    enum OrderType {
        Buy,
        Sell
    }
    enum ConditionType {
        TimeBased,
        EventBased,
        PriceBased
    }
    enum Logic {
        AND,
        OR
    }

    struct Condition {
        ConditionType conditionType;
        uint256 value;
    }

    struct Order {
        address user;
        OrderType orderType;
        address asset;
        uint256 amount;
        Condition[] conditions;
        Logic logic;
        bool executed;
    }

    uint256 public orderCount = 0;
    mapping(uint256 => Order) public orders;

    event OrderCreated(uint256 orderId, address indexed user);
    event OrderExecuted(uint256 orderId);
    event TradeExecuted(uint256 orderId, OrderType orderType, address asset, uint256 amount);


    // constructor() {
    //     owner = msg.sender;
    // }
    constructor() Ownable(msg.sender) {
            priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    }

    function createOrder(
        OrderType _orderType,
        address _asset,
        uint256 _amount,
        Condition[] memory _conditions,
        Logic _logic
    ) public whenNotPaused returns (uint256) {
        orderCount++;
        Order storage newOrder = orders[orderCount];
        newOrder.user = msg.sender;
        newOrder.orderType = _orderType;
        newOrder.asset = _asset;
        newOrder.amount = _amount;
        newOrder.logic = _logic;
        newOrder.executed = false;
        
        // Manually copy each condition from memory to storage.
        for (uint i = 0; i < _conditions.length; i++) {
            newOrder.conditions.push(_conditions[i]);
        }

        emit OrderCreated(orderCount, msg.sender);
        return orderCount;
    }

    function getOrder(uint256 _orderId) external view returns (
    address user,
    OrderType orderType,
    address asset,
    uint256 amount,
    Condition[] memory conditions,
    Logic logic,
    bool executed
) {
    Order storage order = orders[_orderId];
    return (
        order.user,
        order.orderType,
        order.asset,
        order.amount,
        order.conditions,
        order.logic,
        order.executed
    );
}

function getLatestPrice() internal view returns (int) {
    (,int price,,,) = priceFeed.latestRoundData();
    return price;
}



    function executeOrder(uint256 _orderId) public whenNotPaused {
        Order storage order = orders[_orderId];
        require(!order.executed, "Order already executed");

        uint256 conditionsMet = 0;
        for (uint i = 0; i < order.conditions.length; i++) {
            if (checkCondition(order.conditions[i])) {
                conditionsMet++;
            }
        }

        if (
            order.logic == Logic.AND && conditionsMet == order.conditions.length
        ) {
            performTrade(order);
                order.executed = true; // set order as executed
        } else if (order.logic == Logic.OR && conditionsMet > 0) {
            performTrade(order);
                order.executed = true; // set order as executed

        }
    }

    // function checkCondition(
    //     Condition memory _condition
    // ) internal view returns (bool) {
    //     if (_condition.conditionType == ConditionType.TimeBased) {
    //         return block.timestamp >= _condition.value;
    //     }
    //     return false;
    //     // ... get data from some other resource like oracle
    // }

    function checkCondition(Condition memory _condition) internal view returns (bool) {
    if (_condition.conditionType == ConditionType.TimeBased) {
        return block.timestamp >= _condition.value;
    }
    
    if (_condition.conditionType == ConditionType.PriceBased) {
        int latestPrice = getLatestPrice();
        // Assuming value is the threshold price for the condition
        return latestPrice >= int(_condition.value); // Needs careful consideration if using other than ETH/USD
    }

    // EventBased can be tricky as it depends on what event you are looking for.
    // You might need another oracle or a method to set the event status on-chain.
    if (_condition.conditionType == ConditionType.EventBased) {
        // Placeholder, implement based on the specific event.
        // return some_event_happened == _condition.value;
    }

    return false;
}


   function performTrade(Order storage order) internal {
    // Placeholder logic for trade execution.
    // In a real-world scenario, this would integrate with an exchange or a DeFi protocol.
    
    if (order.orderType == OrderType.Buy) {
        // Simulate buying the asset for the user
        emit TradeExecuted(orderCount, OrderType.Buy, order.asset, order.amount);
    } else if (order.orderType == OrderType.Sell) {
        // Simulate selling the asset for the user
        emit TradeExecuted(orderCount, OrderType.Sell, order.asset, order.amount);
    }
   }
}