// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// Import required OpenZeppelin,Chainlink and MockChainlink contracts
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./MockChainlinkAggregator.sol";

// A contract to execute conditional orders based on various conditions
contract ConditionalOrder is Pausable, Ownable, ReentrancyGuard {

    // Interface for Chainlink price feeds
    AggregatorV3Interface internal priceFeed;

    // Variable for mock price feed
    MockChainlinkAggregator internal mockFeed;
    bool public isUsingMock = false;

     // Define order types: Buy or Sell
    enum OrderType {Buy,Sell}

    // Define condition types: Time-Based, Event-Based, or Price-Based
    enum ConditionType {TimeBased, EventBased, PriceBased}

    // Logic for checking conditions: AND or OR
    enum Logic {AND, OR}

    // Structure to define a condition
    struct Condition {
        ConditionType conditionType;    // Type of the condition
        uint256 value;                  // Value for the condition (e.g., timestamp, price)
    }

    struct Order {
        address user;               // Address of the user who created the order
        OrderType orderType;        // Type of the order (Buy/Sell)
        address asset;              // Address of the asset involved
        uint256 amount;             // Amount of the asset involved
        Condition[] conditions;     // Array of conditions for the order
        Logic logic;                // Logic to check conditions
        bool executed;              // Status of the order (executed or not)
    }

    uint256 public orderCount = 0;
    mapping(uint256 => Order) public orders; // Mapping from order ID to Order structure

    // Events for order creation, execution, and trade
    event OrderCreated(uint256 orderId, address indexed user);
    event OrderExecuted(uint256 orderId);
    event TradeExecuted(uint256 orderId, OrderType orderType, address asset, uint256 amount);
    event OrderCanceled(uint256 orderId);
    
    // Constructor to initialize the price feed
    constructor(bool useMock) Ownable(msg.sender) {
        if (useMock) {
            mockFeed = new MockChainlinkAggregator(2000e8); // initializes the mock feed with a price of 2000 with 8 decimals
            isUsingMock = true;
        } else {
            priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        }
    }

    /**
    * @dev Creates a new conditional order
    * @param _orderType Type of the order (Buy or Sell)
    * @param _asset Address of the asset involved in the order
    * @param _amount Amount of the asset involved
    * @param _conditions Array of conditions for the order
    * @param _logic Logic to evaluate conditions (AND/OR)
    *
    * @return Order ID of the created order
    */

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

            for (uint256 i = 0; i < _conditions.length; i++) {
                newOrder.conditions.push(_conditions[i]);
            }

            emit OrderCreated(orderCount, msg.sender);
            return orderCount;
    }

    /**
    * @dev Fetches details of a specific order
    * @param _orderId ID of the order to fetch
    *
    */

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

    function switchToMock() external onlyOwner {
        require(!isUsingMock, "Already using Mock");
        mockFeed = new MockChainlinkAggregator(2000e8);
        isUsingMock = true;
    }

    function switchToReal() external onlyOwner {
        require(isUsingMock, "Already using Real Feed");
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        isUsingMock = false;
    }

    function getLatestPrice() internal view returns (int256) {
        if (isUsingMock) {
            (, int256 price, , , ) = mockFeed.latestRoundData();
            return price;
        } else {
            (, int256 price, , , ) = priceFeed.latestRoundData();
            return price;
        }
    }


        /**
    * @dev Executes a conditional order if its conditions are met
    * @param _orderId ID of the order to execute
    */

    function executeOrder(uint256 _orderId) public whenNotPaused nonReentrant() {
        Order storage order = orders[_orderId];
        require(!order.executed, "Order already executed");

        uint256 conditionsMet = 0;
        for (uint256 i = 0; i < order.conditions.length; i++) {
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


    /**
    * @dev Checks if a specific condition of an order is met
    * @param _condition Condition to check
    *
    * @return True if condition is met, otherwise false
    */

    function checkCondition(Condition memory _condition) internal view returns (bool) {
        if (_condition.conditionType == ConditionType.TimeBased) {
            return block.timestamp >= _condition.value;
        }
    
        if (_condition.conditionType == ConditionType.PriceBased) {
            int256 latestPrice = getLatestPrice();
            // Assuming value is the threshold price for the condition
            return latestPrice >= int256(_condition.value); // Needs careful consideration if using other than ETH/USD
        }

        // EventBased can be tricky as it depends on what event you are looking for.
        // You might need another oracle or a method to set the event status on-chain.
        if (_condition.conditionType == ConditionType.EventBased) {
            // Placeholder, implement based on the specific event.
            // return some_event_happened == _condition.value;
        }

        return false;
    }

    /**
    * @dev Performs a trade for a given order (placeholder logic)
    * @param order Order to perform the trade for
    */

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

    function cancelOrder(uint256 _orderId) public whenNotPaused {
        Order storage order = orders[_orderId];
        require(order.user == msg.sender, "Only order creator can cancel");
        require(!order.executed, "Order already executed");

        order.executed = true; // Mark the order as executed to prevent further operations
        emit OrderCanceled(_orderId);
    }
}

