// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {VegaVoteToken} from "../src/VegaVoteToken.sol";
import {Staking} from "../src/Stacking.sol";
import {VotingSystem} from "../src/Voting.sol";
import {VoteResultNFT} from "../src/Result_NFT.sol";

contract VotingTest is Test {
    VegaVoteToken token;
    Staking staking;
    VoteResultNFT nft;
    VotingSystem voting;
    address admin = address(0x123);
    address user1 = address(0x456);

    function setUp() public {
        token = new VegaVoteToken();
        staking = new Staking(address(token));
        nft = new VoteResultNFT();
        voting = new VotingSystem(address(staking), address(nft));

        // Настройка стейкинга для пользователя
        token.mint(user1, 1000);
        vm.prank(user1);
        token.approve(address(staking), 1000);
        vm.prank(user1);
        staking.stake(1000, 365 days); // votingPower = 1000 * (365*86400)^2
    }

    function testVoteFlow() public {
        vm.prank(admin);
        voting.createSession("Test Vote", 1 hours, 1000);

        vm.prank(user1);
        voting.vote(0, true);

        uint256 yesVotes = voting.getSessionYesVotes(0);
        uint256 noVotes = voting.getSessionNoVotes(0);
        assertGt(yesVotes, 0);
        assertEq(noVotes, 0);
    }

    function testDeadlineFinalization() public {
        vm.prank(admin);
        voting.createSession("Test Vote", 1 hours, 1000);

        vm.warp(block.timestamp + 2 hours);
        voting.checkDeadline(0);

        bool isFinalized = voting.isSessionFinalized(0);
        assertTrue(isFinalized);
    }
}
