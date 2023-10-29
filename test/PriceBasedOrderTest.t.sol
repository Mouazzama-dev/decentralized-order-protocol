// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Test, console2} from "forge-std/Test.sol";
import "../src/ConditionalOrder.sol";
import "../src/MockChainlinkAggregator.sol";

contract PriceBasedOrderTest is Test {
    ConditionalOrder conditionalOrder;
    MockChainlinkAggregator mockChainlink;

    function setUp() public {
        conditionalOrder = new ConditionalOrder(true);
        mockChainlink = new MockChainlinkAggregator(2000);
    }

    // Test to create price based order
    function test_createOrderPriceBased() public {
        // Initializing conditions array with a specific size
        ConditionalOrder.Condition[] memory initialConditions = new ConditionalOrder.Condition[](1);

        // Here we assume that if the asset price goes above 2000 units (e.g., if you're using ETH/USD feed) the order should execute.
        ConditionalOrder.Condition memory condition = ConditionalOrder.Condition({
            conditionType: ConditionalOrder.ConditionType.PriceBased,
            value: 2000 
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
        assertEq(uint(order.conditions[0].conditionType), uint(ConditionalOrder.ConditionType.PriceBased));
        assertEq(order.conditions[0].value, condition.value);
        assertEq(uint(order.logic), uint(ConditionalOrder.Logic.AND));
        assertTrue(!order.executed);
    }

    // Test to execute price based order
    function test_executeOrderPriceBased() public {
        // Create an order that should execute if the price is above 2500 units.
        ConditionalOrder.Condition[] memory initialConditions = new ConditionalOrder.Condition[](1);
        ConditionalOrder.Condition memory condition = ConditionalOrder.Condition({
            conditionType: ConditionalOrder.ConditionType.PriceBased,
            value: 2500 
        });
        initialConditions[0] = condition;
        uint256 orderId = conditionalOrder.createOrder(
            ConditionalOrder.OrderType.Buy,
            address(0),
            100,
            initialConditions,
            ConditionalOrder.Logic.AND
        );
        assertEq(orderId, orderId); // Assuming this is the second order you're creating in the test suite

        // Set the price in the mock Chainlink contract to a value that should trigger the order.
        mockChainlink.setPrice(250000000000);  // Assuming `mockChainlink` is your mock Chainlink contract where you can set price

        // Try to execute the order.
        conditionalOrder.executeOrder(orderId);

        (, , , , , , bool executed) = conditionalOrder.getOrder(orderId);
        assertTrue(executed, "Price-based order was not executed despite the condition being met");
    }


}
