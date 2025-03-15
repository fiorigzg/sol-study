// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Store is Ownable {

    /// @notice buyer => product id => quantity
    mapping(address => mapping(uint256 => uint256)) public userPurchase;
    /// @notice product id => quantity
    mapping(uint256 => uint256) public productPurchase;
    /// @notice discount code => discount in percents (1-100)
    mapping(string => uint256) public discountCodes;

    struct Product {
        string name;
        uint256 id;
        uint256 stock;
        uint256 price;
    }

    Product[] private products;

    event Purchase(address _buyer, uint256 _id, uint256 _quantity);
    event Refund(address _refounder, uint256 _id, uint256 _quantity);

    error IdAlreadyExist();
    error IdDoesNotExist();
    error NoMoney();
    error OutOfStock();
    error ZeroQuantity();
    error NotEnoughFunds();
    error NotEnoughProducts();
    error WrongBatchStructure();
    error IncorrectDiscount();

    constructor(address initialOwner) Ownable(initialOwner) {}

    function getProducts() public view returns(Product[] memory) {
        return products;
    }

    function getTopSelling() public view returns(uint256[3] memory) {
        uint256[3] memory topSelling = [type(uint).max, type(uint).max, type(uint).max];
        uint256[] memory topSelled = new uint256[](3);

        for (uint place = 0; place < 3; place++) {
            for (uint i = 0; i < products.length; i++) {
                Product storage product = products[i];

                bool isSkip = false;
                for (uint placed = 0; placed < place; placed++) {
                    if (product.id == topSelling[placed]) isSkip = true;
                }

                if (topSelled[place] < productPurchase[product.id] && !isSkip) {
                    topSelled[place] = productPurchase[product.id];
                    topSelling[place] = product.id;
                }
            }
        }

        return topSelling;
    }

    function getTotalRevenue() public view returns(uint256) {
        uint256 totalRevenue = 0;

        for (uint i = 0; i < products.length; i++) {
            Product storage product = products[i];
            totalRevenue += productPurchase[product.id] * product.price;
        }

        return totalRevenue;
    }

    function getUserPurchase(address _userAddress) public view returns(uint256) {
        uint256 userPurchased = 0;

        for (uint i = 0; i < products.length; i++) {
            Product storage product = products[i];
            userPurchased += userPurchase[_userAddress][product.id] * product.price;
        }

        return userPurchased;
    }

    function buy(uint256 _id, uint256 _quantity, string calldata _discountCode) external payable {
        if (_quantity <= 0) revert ZeroQuantity();
        if (getStock(_id) < _quantity) revert OutOfStock();

        uint256 productPrice = getPrice(_id);
        productPrice -= productPrice * discountCodes[_discountCode] / 100;
        uint256 totalPrice = productPrice * _quantity;
        if (msg.value < totalPrice) revert NotEnoughFunds();

        _buyProcess(msg.sender, _id, _quantity);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function refund(uint256 _id, uint256 _quantity) external {
        if (_quantity <= 0) revert ZeroQuantity();
        if (userPurchase[msg.sender][_id] < _quantity) revert NotEnoughProducts();

        uint256 balance = address(this).balance;
        Product storage product = _findProduct(_id);

        if (balance < _quantity * product.price) revert NoMoney();

        product.stock += _quantity;

        userPurchase[msg.sender][_id] -= _quantity;
        productPurchase[_id] -= _quantity;
        payable(msg.sender).transfer(_quantity * product.price);

        emit Refund(msg.sender, _id, _quantity);
    }

    function batchBuy(uint256[] calldata _ids, uint256[] calldata _quantities, string calldata _discountCode) external payable {
        if (_ids.length != _quantities.length) revert WrongBatchStructure();

        uint256 totalPrice = 0;
        for (uint i = 0; i < _ids.length; i++) {
            uint256 q = _quantities[i];
            uint256 id = _ids[i];

            if (q <= 0) revert ZeroQuantity();
            if (getStock(i) < q) revert OutOfStock();

            uint256 productPrice = getPrice(id);
            productPrice -= productPrice * discountCodes[_discountCode] / 100;
            totalPrice += productPrice * q;
        }

        if (msg.value < totalPrice) revert NotEnoughFunds();

        for (uint i = 0; i < _ids.length; i++) {
            uint256 q = _quantities[i];
            uint256 id = _ids[i];

            _buyProcess(msg.sender, id, q);
        }

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoMoney();

        payable(owner()).transfer(balance);
    }

    function addProduct(string calldata _name, uint256 _id, uint256 _stock, uint256 _price) external onlyOwner {
        if (_isIdExist(_id)) revert IdAlreadyExist();
        products.push(Product(_name, _id, _stock, _price));
    }

    function addDiscountCode(string calldata _code, uint256 _discount) external onlyOwner {
        if (_discount <= 0 || _discount > 100) revert IncorrectDiscount();
        discountCodes[_code] = _discount;
    }

    function deleteProduct(uint256 _id) external onlyOwner {
        (bool status, uint256 index) = _findIndexById(_id);
        if (!status) revert IdDoesNotExist();

        products[index] = products[products.length - 1];
        products.pop();
    }

    function updatePrice(uint256 _id, uint256 _price) external onlyOwner {
        Product storage product = _findProduct(_id);
        product.price = _price;
    }

    function updateStock(uint256 _id, uint256 _stock) external onlyOwner {
        Product storage product = _findProduct(_id);
        product.stock = _stock;
    }

    function getPrice(uint256 _id) public view returns(uint256) {
        Product storage product = _findProduct(_id);
        return product.price;
    }

    function getStock(uint256 _id) public view returns(uint256) {
        Product storage product = _findProduct(_id);
        return product.stock;
    }

    function _findProduct(uint256 _id) internal view returns(Product storage product) {
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _id) return products[i];
        }

        revert ("Product not found");
    }

    function _buyProcess(address _buyer, uint256 _id, uint256 _quantity) internal {
        Product storage product = _findProduct(_id);
        product.stock -= _quantity;

        userPurchase[_buyer][_id] += _quantity;
        productPurchase[_id] += _quantity;

        emit Purchase(_buyer, _id, _quantity);
    }

    function _isIdExist(uint256 _id) internal view returns(bool) {
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _id) return true;
        }
        return false;
    }

    function _findIndexById(uint256 _id) internal view returns(bool, uint256) {
        for (uint i = 0; i < products.length; i++) {
            if (products[i].id == _id) return (true, i);
        }
        return (false, 0);
    }

    // add refund function + 
    // add top selling products function + 
    // add get total revenue function +
    // add get user purchase function +
    // add discount codes functionality +
    // add struct purchase -
}