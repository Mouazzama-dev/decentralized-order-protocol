// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Test, console2} from "forge-std/Test.sol";
import "../src/ConditionalOrder.sol";

contract ConditionalOrderTest is Test {
    ConditionalOrder conditionalOrder;

    function setUp() public {
        conditionalOrder = new ConditionalOrder();
    }

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
function test_executeOrderTrade() public {
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

    (
        , , , , ,
        , 
        bool executed
    ) = conditionalOrder.getOrder(orderId);

    // Asserting that the order has been executed
    assertTrue(executed, "Order was not executed");
    
    // In the real-world, you'd also check if the actual trade happened, e.g., by checking token balances or other states.
    // For this example, the emitted event would be the evidence of "trade execution".
}

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



}
