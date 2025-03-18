// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract CounterV1 is UUPSUpgradeable, Ownable, Initializable {
    uint256 public count;
    
    constructor(address initialOwner) Ownable(initialOwner) {
        _disableInitializers(); // Блокируем инициализацию в конструкторе
    }
    
    function initialize() virtual public initializer {
        _transferOwnership(msg.sender);
        count = 0; // Явная инициализация
    }

    function increment() public {
        count += 1;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

}

contract CounterV2 is CounterV1 {
    constructor(address initialOwner) CounterV1(initialOwner) {}

    function initialize() override public reinitializer(2) {
        count = 0;
    }

    function reset() public onlyOwner {
        count = 0;
    }
}