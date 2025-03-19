// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MyProxy} from "./MyProxy.sol";

contract GitContract is Ownable {
    address[] public versionHistory;
    address public currentVersion;
    MyProxy proxy;

    event Upgraded(address indexed newVersion);
    event Rollback(address indexed previousVersion);

    constructor(address payable _proxy, address implementation) Ownable(msg.sender) {
        versionHistory.push(implementation);
        currentVersion = implementation;
        proxy = MyProxy(_proxy);
    }

    function upgradeTo(address newImplementation) public onlyOwner {
        require(newImplementation != address(0), "Invalid version");
        require(newImplementation != currentVersion, "Already active");

        versionHistory.push(newImplementation);
        currentVersion = newImplementation;
        proxy.upgrade(newImplementation);

        emit Upgraded(newImplementation);
    }

    function rollbackTo(uint256 index) public onlyOwner {
        require(index < versionHistory.length, "Invalid index");
        require(index != versionHistory.length - 1, "Already active");

        currentVersion = versionHistory[index];
        proxy.upgrade(currentVersion);

        emit Rollback(currentVersion);
    }

    function getVersionCount() external view returns (uint256) {
        return versionHistory.length;
    }
}