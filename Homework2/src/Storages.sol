// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract StorageV1 is UUPSUpgradeable, Ownable {
    uint256 public value;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setValue(uint256 _value) public {
        value = _value;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

contract StorageV2 is UUPSUpgradeable, Ownable {
    uint256 public value;
    string public text;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setValue(uint256 _value) public {
        value = _value;
    }

    function setText(string memory _text) public {
        text = _text;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}

contract StorageV3 is UUPSUpgradeable, Ownable {
    uint256 public value;
    string public text;
    bool public flag;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setValue(uint256 _value) public {
        value = _value * 2;
    }

    function setFlag(bool _flag) public {
        flag = _flag;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
