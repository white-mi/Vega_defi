// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VersionedProxy is ERC1967Proxy, UUPSUpgradeable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct AppStorage {
        uint256 value;
        mapping(bytes32 => uint256) uintStorage;
        mapping(bytes32 => address) addressStorage;
    }
    
    AppStorage private _appStorage;
    EnumerableSet.AddressSet private _versionHistory;
    address[] private _activationHistory;

    constructor(address implementation, bytes memory data) 
        ERC1967Proxy(implementation, data)
        Ownable(msg.sender)
    {
        _versionHistory.add(implementation);
        _activationHistory.push(implementation);
        if (data.length > 0) {
            Address.functionDelegateCall(implementation, data);
        }
    }

    receive() external payable {} 

    function upgradeTo(address newImplementation) public onlyOwner {
        require(newImplementation.code.length > 0, "Invalid implementation");
        _activationHistory.push(newImplementation);
        //require(!_versionHistory.contains(newImplementation), "Version exists");
        
        //bytes32 newVersionHash = keccak256(abi.encodePacked(newImplementation.code));
        //bytes32 currentVersionHash = keccak256(abi.encodePacked(ERC1967Utils.getImplementation().code));
        //require(newVersionHash == currentVersionHash, "Storage layout changed");
        
        _versionHistory.add(newImplementation);
        ERC1967Utils.upgradeToAndCall(newImplementation, new bytes(0));
    }

    function rollbackTo(uint256 versionIndex) public onlyOwner {
        address targetVersion = _versionHistory.at(versionIndex);
        require(targetVersion != ERC1967Utils.getImplementation(), "Already active");
        _activationHistory.push(targetVersion);
        
        ERC1967Utils.upgradeToAndCall(targetVersion, new bytes(0));
    }

    function getActivatedVersion(uint256 index) public view returns(address) {
        return _activationHistory[index];
    }

    function getVersion(uint256 i) public view returns(address) {
        return _versionHistory.at(i);
    }

    function activationCount() public view returns(uint256) {
        return _versionHistory.length();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}