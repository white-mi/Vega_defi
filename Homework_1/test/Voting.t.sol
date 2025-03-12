// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {IERC20Mintable} from "../src/IERC20Mintable.sol";
import {Staking} from "../src/Stacking.sol";
import {VotingSystem} from "../src/Voting.sol";
import {VoteResultNFT} from "../src/Result_NFT.sol";
import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {VegaVoteToken} from "../src/VegaVoteToken.sol";



contract VotingTest is Test, IERC721Receiver  {
    IERC20Mintable public token;
    VegaVoteToken token_contract;
    Staking public staking;
    VoteResultNFT public nft;
    VotingSystem public voting;
 
    address owner; 
    address admin = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setUp() public {
        uint256 i = 5 ether;
        console.log(i);
        owner = address(this); 
        token_contract = new VegaVoteToken();   //в данных тестах работаю со своим стандартным ERC20 токеном, 
                                                //логика остается той же в сети Sepolia, благодаря использованию универсальных интерфейсов
        token = IERC20Mintable(address(token_contract));
        staking = new Staking(address(token));
        nft = new VoteResultNFT(address(this));
        voting = new VotingSystem(owner, address(staking), address(nft));
        voting.addAdmin(admin);

        console.logAddress(nft.owner());
        console.logAddress(address(voting));
        console.logAddress(address(this));
        nft.transferOwnership(address(voting));
        

        token.transfer(user1, 1000 ether);
        token.transfer(user2, 1000 ether);
        
        vm.startPrank(user1);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 365 days);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(staking), 1000 ether);
        staking.stake(1000 ether, 365 days);
        vm.stopPrank();
    }

    // Тест: Успешное создание сессии голосования 
    function testCreateSession() public {
        console.logAddress(address(this));
        vm.prank(admin);
        voting.createSession("Test Vote 1", 1 days, 1000);
    
        (uint256 id, string memory desc,, uint256 threshold,,,) = voting.sessions(0);
        assertEq(id, 0);
        assertEq(threshold, 1000);
        assertEq(keccak256(bytes(desc)), keccak256(bytes("Test Vote 1")));

    }

    // Тест: Проверка подсчёта VotingPower
    function testVoteSuccess() public {
        vm.prank(admin);
        voting.createSession("Test Vote", 1 days, 1000);

        vm.prank(user1);
        voting.vote(0, true);

        (, , , , uint256 yesVotes, ,) = voting.sessions(0);
        console.log(yesVotes);
        assertEq(yesVotes, 1000 * (365 days) ** 2, "Voting power mismatch");
    }

    //Тест: успешное голосование с выпуском ERC721
    function testWithFinalization() public {
        vm.prank(admin);
        voting.createSession("Test Vote", 1 days, 1000 ); 

        vm.prank(user1);
        voting.vote(0, true);
        console.logAddress(owner);
        vm.prank(admin);
        voting.finalizeAllSessions();
        (, , , , , , bool isFinalized) = voting.sessions(0);
        assertTrue(isFinalized, "Voting should be finalized");
    }

    //Тест: пользователь может вернуть свой токен по истечении срока стейкинга
    function testUnstake() public {
        vm.warp(block.timestamp+366 days);
        console.log(token.balanceOf(user1));
        (uint256 amount, uint256 startTime, uint256 period, bool isWithdrawn) = staking.getStakeInfo(user1, 0);
        console.log(amount);
        console.log(startTime);
        console.log(period);
        console.log(isWithdrawn);
        vm.prank(user1);
        staking.unstake(0);
        (amount, startTime, period, isWithdrawn) = staking.getStakeInfo(user1, 0);
        console.log(amount);
        console.log(startTime);
        console.log(period);
        console.log(isWithdrawn);
        console.log(token.balanceOf(user1));
        assertEq(token.balanceOf(user1), 1000 ether);
    }

    //Тест: Правильное распределние ролей №1
    function testAdminRoleManagement() public {
        vm.prank(owner);
        voting.addAdmin(user1);
        assertTrue(voting.hasRole(voting.ADMIN_ROLE(), user1), "User1 should be admin");
        vm.prank(owner);
        voting.removeAdmin(user1);
        assertFalse(voting.hasRole(voting.ADMIN_ROLE(), user1), "User1 should not be admin");
    }

    //Тест: Правильное распределние ролей №2
    function testOnlyAdminCanCreateSession() public {
        vm.prank(user1);
        vm.expectRevert();
        voting.createSession("Test Vote", 1 days, 1000);
        vm.prank(admin);
        voting.createSession("Test Vote", 1 days, 1000);
        (uint256 id, , , , , , ) = voting.sessions(0);
        assertEq(id, 0, "Session should be created");
    }

    // Тест: Только админ имеет возможность завершать голосования
    function testOnlyAdminCanFinalizeSessions() public {
        vm.prank(admin);
        voting.createSession("Test Vote", 1 days, 1000);
        vm.prank(user1);
        voting.vote(0, false);
        vm.prank(user1);
        vm.expectRevert();
        voting.finalizeAllSessions();
        vm.prank(admin);
        voting.finalizeAllSessions();
        assertEq(nft.balanceOf(admin), 1, "NFT not distributed");
        (, , , , , , bool isFinalized) = voting.sessions(0);
        assertTrue(isFinalized, "Session should be finalized");
    }


    

}