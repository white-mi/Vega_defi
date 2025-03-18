// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CounterV1, CounterV2} from "../src/Counter.sol";
import "../src/StorageContract.sol";

contract CounterTest is Test {
    address constant V1_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant V2_ADDRESS = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address payable public constant PROXY_ADDRESS = payable(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);
    
    CounterV1 public v1;
    CounterV2 public v2;
    VersionedProxy public proxy;
    
    address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; 
    address user = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function setUp() public {
        v1 = CounterV1(V1_ADDRESS);
        v2 = CounterV2(V2_ADDRESS);
        proxy = VersionedProxy(PROXY_ADDRESS);
    }


    function testUpgrade() public {
        vm.prank(owner);
        proxy.upgradeTo(address(v2));
        
        CounterV2 upgraded = CounterV2(address(proxy));
        
        assertEq(upgraded.count(), 0, "Count should persist after upgrade");
        
        upgraded.increment();
        vm.prank(owner);
        upgraded.reset();
        assertEq(upgraded.count(), 0, "Reset should work in V2");
    }

    function testRollback() public {
        CounterV1 instance = CounterV1(address(proxy));
        
        instance.increment();
        instance.increment();
        assertEq(instance.count(), 2, "Increment should work");

        vm.prank(owner);
        proxy.upgradeTo(address(v2));
        CounterV2 upgraded = CounterV2(address(proxy));
        
        upgraded.increment();
        assertEq(upgraded.count(), 3, "V2 increment should work");

        vm.prank(owner);
        proxy.rollbackTo(0);
        CounterV1 rolledBack = CounterV1(address(proxy));
        
        assertEq(rolledBack.count(), 3, "State should persist after rollback");
        rolledBack.increment();
        assertEq(rolledBack.count(), 4, "V1 should work after rollback");
    }

    function testSafeRollback() public {
        CounterV1 instance = CounterV1(address(proxy));
        instance.increment();
        instance.increment();
        assertEq(instance.count(), 2);

        vm.prank(owner);
        proxy.upgradeTo(address(v2));
        
        CounterV2 upgraded = CounterV2(address(proxy));
        upgraded.increment();
        assertEq(upgraded.count(), 3);

        vm.prank(owner);
        proxy.rollbackTo(0);
        
        CounterV1 rolledBack = CounterV1(address(proxy));
        assertEq(rolledBack.count(), 3);
        rolledBack.increment();
        assertEq(rolledBack.count(), 4); 
    }
    
    function testSecurity() public {
        vm.prank(user);
        vm.expectRevert();
        proxy.upgradeTo(address(v2));

        vm.prank(user);
        vm.expectRevert();
        proxy.rollbackTo(0);

        vm.prank(owner);
        vm.expectRevert();
        proxy.rollbackTo(999);
    }

    function testMultipleUpgrades() public {
        CounterV1 instance = CounterV1(address(proxy));
        instance.increment();
        
        vm.prank(owner);
        proxy.upgradeTo(address(v2));
        CounterV2 v2Instance = CounterV2(address(proxy));
        vm.prank(owner);
        v2Instance.reset();

        console.log(proxy.activationCount());
        
        vm.prank(owner);
        proxy.rollbackTo(0);
        CounterV1 v1Instance = CounterV1(address(proxy));
        assertEq(v1Instance.count(), 0, "State should be from last V2 change");
        
        vm.prank(owner);
        proxy.upgradeTo(address(v2));
        CounterV2 newV2Instance = CounterV2(address(proxy));
        newV2Instance.increment();
        
        console.log(proxy.getActivatedVersion(2));
        
        assertEq(proxy.getActivatedVersion(0), address(v1), "Version 0 should be V1");
        assertEq(proxy.getActivatedVersion(1), address(v2), "Version 1 should be V2");
        assertEq(proxy.getActivatedVersion(2), address(v1), "Version 2 should be V1");
        assertEq(proxy.getActivatedVersion(3), address(v2), "Version 3 should be V2");
    }

    function testReinitialization() public {
        vm.prank(owner);
        vm.expectRevert();
        CounterV1(address(proxy)).initialize();
    }
}
