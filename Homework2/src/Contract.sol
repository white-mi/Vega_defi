pragma solidity ^0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract CounterV2 is UUPSUpgradeable {
    uint256 public count;

    function inc() public {
        count += 1;
    }

    function dec() public {
        count -= 1;
    }

    function get() public view returns (uint256) {
        return count * 42;
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}