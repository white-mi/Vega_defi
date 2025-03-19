// script/Rollback.s.sol
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {GitContract} from "../src/GitContract.sol";

contract Rollback is Script {
    function run() external {
        address gitAddress = vm.envAddress("GIT_CONTRACT");
        address owner = vm.envAddress("OWNER");
        uint256 targetVersion = vm.envUint("TARGET_VERSION");
        
        vm.startBroadcast(owner);
        GitContract(gitAddress).rollbackTo(targetVersion);
        vm.stopBroadcast();
    }
}