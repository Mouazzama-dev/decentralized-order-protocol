// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeBasedOrder {
    address public owner;

    // Enums for clear definition of order statuses and types.
    enum OrderStatus { Pending, Executed, Cancelled }
    enum OrderType { Buy, Sell }

    // Struct for capturing order details.
    struct Order {
        address user;
        OrderType orderType;
        uint256 amount;
        uint256 price;
        uint256 expirationTime;
        OrderStatus status;
    }

    // State variables.
    mapping(uint256 => Order) public orders;       // Orders storage.
    mapping(address => uint256) public balances;   // User balances storage.
    uint256 public orderCounter;

    // Modifiers.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Events for easier frontend integration and state change monitoring.
    event OrderPlaced(uint256 indexed orderId, address indexed user, OrderType orderType, uint256 amount, uint256 price);
    event OrderExecuted(uint256 indexed orderId);
    event OrderCancelled(uint256 indexed orderId);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // Constructor to initialize contract state.
    constructor() {
        owner = msg.sender;
        orderCounter = 0;
    }

    // Deposit function allowing users to deposit Ether to the contract.
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    // Withdrawal function allowing users to retrieve their Ether.
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    // Function to place a new order.
    function placeOrder(
        OrderType _orderType,
        uint256 _amount,
        uint256 _price,
        uint256 _timeToExpire
    ) external {
        orderCounter++;

        orders[orderCounter] = Order({
            user: msg.sender,
            orderType: _orderType,
            amount: _amount,
            price: _price,
            expirationTime: block.timestamp + _timeToExpire,
            status: OrderStatus.Pending
        });

        emit OrderPlaced(orderCounter, msg.sender, _orderType, _amount, _price);
    }

    // Execute an order and simulate trade execution.
    function executeOrder(uint256 orderId) external {
        Order storage order = orders[orderId];

        require(block.timestamp < order.expirationTime, "Order has expired");
        require(order.status == OrderStatus.Pending, "Order is not in Pending status");

        uint256 tradeValue = order.amount * order.price;
        require(balances[msg.sender] >= tradeValue, "Insufficient balance to execute the order");

        // Handling buy orders.
        if (order.orderType == OrderType.Buy) {
            balances[order.user] += order.amount;
            balances[msg.sender] -= tradeValue;
        }
        // Handling sell orders.
        else if (order.orderType == OrderType.Sell) {
            balances[order.user] -= order.amount;
            balances[msg.sender] += tradeValue;
        }

        order.status = OrderStatus.Executed;
        emit OrderExecuted(orderId);
    }

    // Function to cancel an existing order.
    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];

        require(msg.sender == order.user, "Not your order");
        require(order.status == OrderStatus.Pending, "Order can't be cancelled now");

        order.status = OrderStatus.Cancelled;
        emit OrderCancelled(orderId);
    }
}
