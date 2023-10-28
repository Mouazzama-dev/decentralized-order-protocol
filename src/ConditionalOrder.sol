// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// Import OpenZeppelin's Pausable contract
import "@openzeppelin/contracts/security/Pausable.sol";

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
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

}