// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/MyProxy.sol";
import "../src/GitContract.sol";
import {StorageV1, StorageV2, StorageV3} from "../src/Storages.sol";

contract ProxyTest is Test {
    address owner = address(0x98);
    address hacker = address(0x666);
    MyProxy proxy;
    GitContract versionController;

    StorageV1 v1;
    StorageV2 v2;
    StorageV3 v3;

    function setUp() public {
        vm.startPrank(owner);
        
        v1 = new StorageV1(owner);
        v2 = new StorageV2(owner);
        v3 = new StorageV3(owner);

        proxy = new MyProxy(address(v1), "", owner);
        versionController = new GitContract(payable(address(proxy)), address(v1));
        
        proxy.transferOwnership(address(versionController));
        vm.stopPrank();
    }

    // Тест 1: Проверка начального состояния
    function test_initialization() public view {
        assertEq(versionController.currentVersion(), address(v1), "Initial version should be V1");
        assertEq(versionController.getVersionCount(), 1, "Initial history length");
        assertEq(proxy.owner(), address(versionController), "Ownership transfer");
    }

    // Тест 2: Полный цикл апгрейда до V2
    function test_full_upgrade_flow_to_v2() public {
        vm.prank(owner);
        versionController.upgradeTo(address(v2));

        StorageV2 upgraded = StorageV2(address(proxy));
        upgraded.setValue(100);
        upgraded.setText("test_v2");

        assertEq(upgraded.value(), 100, "V2 value set");
        assertEq(upgraded.text(), "test_v2", "V2 text set");
        assertEq(versionController.currentVersion(), address(v2), "Current version after upgrade");
        assertEq(versionController.getVersionCount(), 2, "History after upgrade");
    }

    // Тест 3: Откат с проверкой данных
    function test_rollback_with_data_persistence() public {
        StorageV1(address(proxy)).setValue(100);
        
        vm.startPrank(owner);
        versionController.upgradeTo(address(v2));
        versionController.rollbackTo(0);
        vm.stopPrank();

        StorageV1 rolledBack = StorageV1(address(proxy));
        assertEq(rolledBack.value(), 100, "Data persistence after rollback");
        assertEq(versionController.currentVersion(), address(v1), "Version after rollback");
    }

    // Тест 4: Множественные апгрейды с разной логикой. 
    //Ключевое - не можем смотерть в поле V3 после оката к V2.
    function test_multiple_upgrades_with_different_versions() public {
        vm.startPrank(owner);
        
        versionController.upgradeTo(address(v2));
        StorageV2 upgradedV2 = StorageV2(address(proxy));
        upgradedV2.setValue(50);
        
        versionController.upgradeTo(address(v3));
        StorageV3 upgradedV3 = StorageV3(address(proxy));
        upgradedV3.setValue(30);
        upgradedV3.setFlag(true);
        
        assertEq(upgradedV3.value(), 60, "V3 double value logic");
        assertTrue(upgradedV3.flag(), "V3 flag set");

        versionController.rollbackTo(1);
        upgradedV2 = StorageV2(address(proxy));
        
        assertEq(upgradedV2.value(), 60, "Data persistence V3->V2");
        
        vm.expectRevert();
        StorageV3(address(proxy)).setFlag(false);

        vm.stopPrank();
    }

    // Тест 5: Попытка несанкционированного апгрейда
    function test_unauthorized_upgrade_attempt() public {
        vm.prank(hacker);
        vm.expectRevert();
        versionController.upgradeTo(address(v2));
    }

    // Тест 6: Попытка отката на несуществующую версию
    function test_invalid_rollback_attempt() public {
        vm.startPrank(owner);
        versionController.upgradeTo(address(v2));
        
        vm.expectRevert();
        versionController.rollbackTo(5); // Несуществующий индекс
        
        vm.expectRevert();
        versionController.rollbackTo(2); // Индекс за пределами истории
        vm.stopPrank();
    }
}