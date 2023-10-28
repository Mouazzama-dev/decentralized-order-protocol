// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// Import OpenZeppelin's Pausable and ownable contract
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ConditionalOrder is Pausable, Ownable {
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

    // constructor() {
    //     owner = msg.sender;
    // }
    constructor() Ownable(msg.sender) {}

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


    // function executeOrder(uint256 _orderId) public whenNotPaused {
    //     Order storage order = orders[_orderId];
    //     require(!order.executed, "Order already executed");

    //     uint256 conditionsMet = 0;
    //     for (uint i = 0; i < order.conditions.length; i++) {
    //         if (checkCondition(order.conditions[i])) {
    //             conditionsMet++;
    //         }
    //     }

    //     if (
    //         order.logic == Logic.AND && conditionsMet == order.conditions.length
    //     ) {
    //         performTrade(order);
    //     } else if (order.logic == Logic.OR && conditionsMet > 0) {
    //         performTrade(order);
    //     }
    // }

    // function checkCondition(
    //     Condition memory _condition
    // ) internal view returns (bool) {
    //     if (_condition.conditionType == ConditionType.TimeBased) {
    //         return block.timestamp >= _condition.value;
    //     }
    //     // ... get data from some other resource like oracle
    // }

    // function performTrade(Order storage order) internal {
    //     // ... the main trading logic shoudl be written here 
    // }
}
