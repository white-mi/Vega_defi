// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {VegaVoteToken} from "../src/VegaVoteToken.sol";
import {Staking} from "../src/Stacking.sol";
import {VotingSystem} from "../src/Voting.sol";
import {VoteResultNFT} from "../src/Result_NFT.sol";
import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";



contract VotingTest is Test, IERC721Receiver  {
    VegaVoteToken token;

    Staking staking;
    VoteResultNFT nft;
    VotingSystem voting;
    
    address owner; 
    address admin = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setUp() public {
        owner = address(this); 
        token = new VegaVoteToken();
        staking = new Staking(address(token));
        nft = new VoteResultNFT(address(this));
        voting = new VotingSystem(address(staking), address(nft));
        console.log(msg.sender);

        voting.addAdmin(admin);

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

    // Тест 1: Успешное создание сессии голосования (Passed)
    function testCreateSession() public {
        console.logAddress(address(this));
        vm.prank(admin);
        voting.createSession("Test Vote 1", 1 days, 1000);
    
        (uint256 id, string memory desc,, uint256 threshold,,,) = voting.sessions(0);
        assertEq(id, 0);
        assertEq(threshold, 1000);
        assertEq(keccak256(bytes(desc)), keccak256(bytes("Test Vote 1")));

    }

    function testVoteSuccess() public {
        vm.prank(admin);
        voting.createSession("Test Vote", 1 days, 1000);

        vm.prank(user1);
        voting.vote(0, true);

        (, , , , uint256 yesVotes, ,) = voting.sessions(0);
        console.log(yesVotes);
        assertEq(yesVotes, 1000 * (365 days) ** 2, "Voting power mismatch");
    }

    function testAutoFinalization() public {
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

    function testUnstake() public {
        vm.warp(block.timestamp+366 days);
        vm.prank(user1);
        staking.unstake(0);
        console.log(token.balanceOf(user1));
        assertEq(token.balanceOf(user1), 1000 ether);
    }

    

}