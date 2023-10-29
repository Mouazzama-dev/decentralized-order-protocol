// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Test, console2} from "forge-std/Test.sol";
import "../src/ConditionalOrder.sol";
import "../src/MockChainlinkAggregator.sol";

contract CancelOrderTest is Test {
    ConditionalOrder conditionalOrder;
    MockChainlinkAggregator mockChainlink;

    function setUp() public {
        conditionalOrder = new ConditionalOrder(true);
        mockChainlink = new MockChainlinkAggregator(2000);
    }

    // Test to cancel order 
    function test_cancelOrder() public {
    // First, let's create a simple order for testing.
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

    // Now, let's cancel the order.
    conditionalOrder.cancelOrder(orderId);

    (, , , , , , bool executed) = conditionalOrder.getOrder(orderId);

    // Asserting that the order has been marked as executed
    assertTrue(executed, "Order was not canceled");
}


}
