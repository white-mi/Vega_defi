pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "../src/Storages.sol";
import "../src/GitContract.sol";

contract Upgrade is Script {
    function run() external {
        address gitAddress = vm.envAddress("GIT_CONTRACT");
        address owner = vm.envAddress("OWNER");
        
        vm.startBroadcast(owner);

        StorageV3 v3 = new StorageV3(owner);
        GitContract(gitAddress).upgradeTo(address(v3));
        
        vm.stopBroadcast();
    }
}