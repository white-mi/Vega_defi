// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "../src/StorageContract.sol";
import "../src/Counter.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        
        vm.startBroadcast(deployerPrivateKey);
        CounterV1 v1 = new CounterV1(deployer);
        CounterV2 v2 = new CounterV2(deployer);

        bytes memory initData = abi.encodeWithSignature("initialize()");
        VersionedProxy proxy = new VersionedProxy(address(v1), initData);

        vm.stopBroadcast();

        console.log("CounterV1:", address(v1));
        console.log("CounterV2:", address(v2));
        console.log("Proxy:", address(proxy));
    }
}
