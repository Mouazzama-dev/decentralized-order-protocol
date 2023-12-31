// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Test, console2} from "forge-std/Test.sol";
import "../src/ConditionalOrder.sol";
import "../src/MockChainlinkAggregator.sol";

contract TimeBasedOrderTest is Test {
    ConditionalOrder conditionalOrder;
    MockChainlinkAggregator mockChainlink;

    function setUp() public {
        conditionalOrder = new ConditionalOrder(true);
        mockChainlink = new MockChainlinkAggregator(2000);
    }

    // Test to create Order which is time based
    function test_createOrderTimeBased() public {
        // Initializing conditions array with a specific size
        ConditionalOrder.Condition[] memory initialConditions = new ConditionalOrder.Condition[](1);
        
        ConditionalOrder.Condition memory condition = ConditionalOrder.Condition({
            conditionType: ConditionalOrder.ConditionType.TimeBased,
            value: block.timestamp + 1 hours
        });
        
        initialConditions[0] = condition;

        uint256 orderId = conditionalOrder.createOrder(
            ConditionalOrder.OrderType.Buy,
            address(0),
            100,
            initialConditions,
            ConditionalOrder.Logic.AND
        );

        // Asserting order ID
        assertEq(orderId, 1);

           // Fetching the order
        (address user, ConditionalOrder.OrderType orderType, address asset, uint256 amount, ConditionalOrder.Condition[] memory fetchedConditions, ConditionalOrder.Logic logic, bool executed) = conditionalOrder.getOrder(orderId);

        ConditionalOrder.Order memory order = ConditionalOrder.Order({
            user: user,
            orderType: orderType,
            asset: asset,
            amount: amount,
            conditions: fetchedConditions,
            logic: logic,
            executed: executed
            });

        // Asserting order details
        assertEq(order.user, address(this));
        assertEq(uint(order.orderType), uint(ConditionalOrder.OrderType.Buy));
        assertEq(order.asset, address(0));
        assertEq(order.amount, 100);
        assertEq(order.conditions.length, 1);
        assertEq(uint(order.conditions[0].conditionType), uint(ConditionalOrder.ConditionType.TimeBased));
        assertEq(order.conditions[0].value, condition.value);
        assertEq(uint(order.logic), uint(ConditionalOrder.Logic.AND));
        assertTrue(!order.executed);
    }

    // Test to execute time based order
    function test_executeOrderTimeBased() public {
        // First, create an order with a TimeBased condition for 2 seconds in the future.
        ConditionalOrder.Condition[] memory initialConditions = new ConditionalOrder.Condition[](1);

        ConditionalOrder.Condition memory condition = ConditionalOrder.Condition({
            conditionType: ConditionalOrder.ConditionType.TimeBased,
            value: block.timestamp + 2 seconds
        });

        initialConditions[0] = condition;

        uint256 orderId = conditionalOrder.createOrder(
            ConditionalOrder.OrderType.Buy,
            address(0),
            100,
            initialConditions,
            ConditionalOrder.Logic.AND
        );

        assertEq(orderId, 1); // Ensure order creation was successful

        // Using vm.wrap to manipulate the EVM time
        vm.warp(block.timestamp + 2 seconds);

        conditionalOrder.executeOrder(orderId);

        (, , , , , , bool executed) = conditionalOrder.getOrder(orderId);

        // Asserting that the order has been executed
        assertTrue(executed, "Order was not executed");

        // In the real-world, we can also check if the actual trade happened, e.g., by checking token balances or other states.
    }




}
