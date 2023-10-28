// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// Import OpenZeppelin's Pausable and ownable contract
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 

contract ConditionalOrder is Pausable {

    enum OrderType { Buy, Sell }
    enum ConditionType { TimeBased, EventBased, PriceBased }
    enum Logic { AND, OR }

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

    constructor() {
        owner = msg.sender;
    }

        function createOrder(
        OrderType _orderType,
        address _asset,
        uint256 _amount,
        Condition[] memory _conditions,
        Logic _logic
    ) public whenNotPaused returns (uint256) {
        orderCount++;
        orders[orderCount] = Order(msg.sender, _orderType, _asset, _amount, _conditions, _logic, false);
        emit OrderCreated(orderCount, msg.sender);
        return orderCount;
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

        if (order.logic == Logic.AND && conditionsMet == order.conditions.length) {
            performTrade(order);
        } else if (order.logic == Logic.OR && conditionsMet > 0) {
            performTrade(order);
        }
    }

}