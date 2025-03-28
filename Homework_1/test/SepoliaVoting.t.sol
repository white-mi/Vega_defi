// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {VotingSystem} from "../src/Voting.sol";
import {Staking} from "../src/Staking.sol";
import {VoteResultNFT} from "../src/Result_NFT.sol";
import {IERC20Mintable} from "../src/IERC20Mintable.sol";

contract LiveNetworkTest is Test {
    address constant STAKING_ADDRESS = 0x95f853852FacBdf4a6F34D63bE6dbF864A5Ef695 ;
    address constant VOTING_ADDRESS = 0x45B5904B2180261e050B83a293d9f4D2194083b8;
    address constant NFT_ADDRESS = 0xEf947b86CF445d32D5c67d5019fada1BCA7a6af5;
    address constant ERC20_ADDRESS = 0xD3835FE9807DAecc7dEBC53795E7170844684CeF;

    address constant ADMIN = 0xC4ce21C3FBA666C4EE33346b88932a7BBB4c65e2;
    address constant USER1 = address(0x1);
    address constant USER2 = address(0x2);

    VotingSystem voting;
    Staking staking;
    VoteResultNFT nft;
    IERC20Mintable token;

    function setUp() public {
        voting = VotingSystem(VOTING_ADDRESS);
        staking = Staking(STAKING_ADDRESS);
        nft = VoteResultNFT(NFT_ADDRESS);
        token = IERC20Mintable(ERC20_ADDRESS);
        token.mint(USER1, 1000 ether);
        token.mint(USER2, 1000 ether);
        vm.prank(ADMIN);
        nft.transferOwnership(address(voting));
    }

    function testFullWorkflow() public {
        vm.prank(USER1);
        token.approve(STAKING_ADDRESS, 1000 ether);
        
        vm.prank(USER1);
        staking.stake(1000 ether, 365 days);
        console.log("Staked 1000 ETH for 365 days. Voting power:", staking.calculateVotingPower(USER1));

        vm.prank(ADMIN);
        voting.createSession("Proposal #1", 1 days, 40);
        console.log("Created session 0: 'Proposal #1'");

        vm.prank(USER1);
        voting.vote(0, true);
        console.log("Voted FOR. Yes votes:", voting.getSessionYesVotes(0), "No votes:", voting.getSessionNoVotes(0));

        vm.prank(ADMIN);
        voting.finalizeAllSessions();

        (, , , , , , bool isFinalized) = voting.sessions(0);
        assertTrue(isFinalized, "Session should be finalized");
        assertEq(nft.balanceOf(ADMIN), 1, "NFT not distributed");
        console.log("NFT minted to ADMIN. Balance:", nft.balanceOf(ADMIN));
        
    }
}