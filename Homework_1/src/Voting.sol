// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import {Staking} from "src/Stacking.sol";
import {VoteResultNFT} from "src/Result_NFT.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";


contract VotingSystem is Ownable {
    struct VoteSession {
        uint256 id;
        string description;
        uint256 deadline;
        uint256 threshold;
        uint256 yesVotes;
        uint256 noVotes;
        bool isFinalized;
        mapping(address => bool) hasVoted;
    }

    Staking public stakingContract;
    VoteResultNFT public nft;
    mapping(uint256 => VoteSession) public sessions;
    uint256 public nextSessionId;

    event VoteStarted(uint256 sessionId, string description);
    event VoteCasted(uint256 sessionId, address voter, bool choice, uint256 power);
    event VoteFinalized(uint256 sessionId, string resultURI);

    constructor(address _stakingContract, address _nft) Ownable(msg.sender) {
        stakingContract = Staking(_stakingContract);
        nft = VoteResultNFT(_nft);
    }

    function createSession(string memory description, uint256 duration, uint256 threshold) external onlyOwner {
        uint256 sessionId = nextSessionId++;
        VoteSession storage session = sessions[sessionId];
        session.id = sessionId;
        session.description = description;
        session.deadline = block.timestamp + duration;
        session.threshold = threshold;
        emit VoteStarted(sessionId, description);
    }

    function getSessionYesVotes(uint256 sessionId) external view returns (uint256) {
        return sessions[sessionId].yesVotes;
    }

    function getSessionNoVotes(uint256 sessionId) external view returns (uint256) {
        return sessions[sessionId].noVotes;
    }

    function isSessionFinalized(uint256 sessionId) external view returns (bool) {
        return sessions[sessionId].isFinalized;
    }

    function vote(uint256 sessionId, bool choice) external {
        VoteSession storage session = sessions[sessionId];
        require(!session.isFinalized, "Voting closed");
        require(block.timestamp <= session.deadline, "Deadline passed");
        require(!session.hasVoted[msg.sender], "Already voted");

        uint256 votingPower = stakingContract.calculateVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");

        if (choice) {
            session.yesVotes += votingPower;
        } else {
            session.noVotes += votingPower;
        }
        session.hasVoted[msg.sender] = true;
        emit VoteCasted(sessionId, msg.sender, choice, votingPower);

        if (session.yesVotes + session.noVotes >= session.threshold) {
            _finalizeVote(sessionId);
        }
    }

    function checkDeadline(uint256 sessionId) external {
        VoteSession storage session = sessions[sessionId];
        require(!session.isFinalized, "Already finalized");
        require(block.timestamp > session.deadline, "Deadline not reached");
        _finalizeVote(sessionId);
    }

    function _finalizeVote(uint256 sessionId) private {
        VoteSession storage session = sessions[sessionId];
        session.isFinalized = true;

        string memory metadataURI = string(abi.encodePacked(
            "ID", Strings.toString(sessionId),
            "/yes/", Strings.toString(session.yesVotes),
            "/no/", Strings.toString(session.noVotes)
        ));

        nft.mint(owner(), metadataURI);
        emit VoteFinalized(sessionId, metadataURI);
    }
}