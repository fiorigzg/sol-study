// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Car {

    bool internal isMoving;
    uint256 internal vin;

    constructor (uint256 _vin) {
        vin = _vin;
    }

    function drive() public virtual {
        isMoving = true;
    }

    function stop() public {
        isMoving = false;
    }

    function status() public view returns(string memory) {
        return isMoving ? "moving" : "stopped";
    }

    function broke() public pure virtual returns(string memory) {
        return "car broken";
    }
}

contract Turbo {
    function turboBoost() public pure returns(string memory) {
        return "TURBO";
    }

    function broke() public pure virtual returns(string memory) {
        return "turbo broken";
    }
}

contract Bmw is Car, Turbo {

    constructor(uint256 _vin) Car(_vin) {

    }

    function drift() public view returns(string memory) {
        require(isMoving, "unable to drift");
        return "drifting";
    }

    function drive() public override {
        super.drive();
        revert("BMW ruined");
    }

    function broke() public pure override(Car, Turbo) returns(string memory) {
        Car.broke();
        Turbo.broke();
        return "all broken";
    }

}