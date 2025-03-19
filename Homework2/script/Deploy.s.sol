// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/MyProxy.sol";
import "../src/GitContract.sol";
import "../src/Storages.sol";

contract Deploy is Script {
    function run() external {
        address owner = vm.envAddress("OWNER");

        vm.startBroadcast(owner);
        
        StorageV1 v1 = new StorageV1(owner);
        
        MyProxy proxy = new MyProxy(address(v1), "", owner);
        GitContract git = new GitContract(payable(address(proxy)), address(v1));
        
        proxy.transferOwnership(address(git));

        console.log("\n====== Deployment Completed ======");
        console.log("Proxy Address:    %s", address(proxy));
        console.log("GitContract Address: %s", address(git));
        
        vm.stopBroadcast();
    }
}