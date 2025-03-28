// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Staking} from "../src/Staking.sol";
import {VoteResultNFT} from "../src/Result_NFT.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IERC721Receiver} from "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract VotingSystem is Ownable, AccessControl, IERC721Receiver {
    using Strings for uint256;

    struct VoteSession {
        uint256 id;
        string description;
        uint256 deadline;
        uint256 threshold;
        uint256 yesVotes;
        uint256 noVotes;
        bool isFinalized;
        mapping(address => bool) hasVoted;
        address[] voters;
    }

    struct ReceivedNFT {
        address contractAddress;
        uint256 tokenId;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    ReceivedNFT[] public receivedNFTs;
    Staking public stakingContract;
    VoteResultNFT public nft;
    mapping(uint256 => VoteSession) public sessions;
    uint256 public nextSessionId;

    event VoteStarted(uint256 sessionId, string description);
    event VoteCasted(uint256 sessionId, address voter, bool choice, uint256 power);
    event VoteFinalized(uint256 sessionId, string metadata);
    event VoteResultsDistributed(uint256 sessionId, address voter, string metadata);
    event NFTReceived(address indexed contractAddress, uint256 indexed tokenId, address indexed from);
    
    constructor(address _owner, address _stakingContract, address _nft) Ownable(_owner) {
        stakingContract = Staking(_stakingContract);
        nft = VoteResultNFT(_nft);
        _grantRole(ADMIN_ROLE, _owner);
    }

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        receivedNFTs.push(ReceivedNFT({
            contractAddress: msg.sender,
            tokenId: tokenId
        }));
        emit NFTReceived(msg.sender, tokenId, from);
        return this.onERC721Received.selector;
    }

    function createSession(string memory description, uint256 duration, uint8 thresholdPercent) external onlyRole(ADMIN_ROLE) {
        require(thresholdPercent > 0 && thresholdPercent <= 100, "Invalid percentage");

        uint256 sessionId = nextSessionId++;
        uint256 totalPower = stakingContract.getTotalVotingPower();
        uint256 calculatedThreshold = (totalPower * thresholdPercent) / 100;

        VoteSession storage session = sessions[sessionId];
        session.id = sessionId;
        session.description = description;
        session.deadline = block.timestamp + duration;
        session.threshold = calculatedThreshold;
        emit VoteStarted(sessionId, description);
    }

    function vote(uint256 sessionId, bool choice) external {
        VoteSession storage session = sessions[sessionId];
        require(!session.isFinalized, "Voting closed");
        require(block.timestamp <= session.deadline, "Deadline passed");
        require(!session.hasVoted[msg.sender], "Already voted");

        uint256 votingPower = stakingContract.calculateVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");
        require(session.yesVotes + session.noVotes <= session.threshold, "Threshold is over");
        require(session.yesVotes + session.noVotes <= session.threshold, "Voting power exceeds session threshold");

        if (choice) {
            session.yesVotes += votingPower;
        } else {
            session.noVotes += votingPower;
        }
        session.hasVoted[msg.sender] = true;
        session.voters.push(msg.sender);
        emit VoteCasted(sessionId, msg.sender, choice, votingPower);
    }

    function finalizeAllSessions() external onlyRole(ADMIN_ROLE)  {
    for (uint256 i = 0; i < nextSessionId; i++) {
        VoteSession storage session = sessions[i];
        if (!session.isFinalized && 
            (block.timestamp > session.deadline || 
             session.yesVotes + session.noVotes >= session.threshold)) 
        {
            _finalizeVote(i);
        }
    }
}

    function _finalizeVote(uint256 sessionId) internal onlyRole(ADMIN_ROLE) {
        VoteSession storage session = sessions[sessionId];
        session.isFinalized = true;

        string memory metadata = string(abi.encodePacked(
            '{"session":', sessionId.toString(),
            ',"yes":', session.yesVotes.toString(),
            ',"no":', session.noVotes.toString(),
            '}'
        ));

        nft.mint(msg.sender, metadata);
        emit VoteFinalized(sessionId, metadata);

        for (uint256 i = 0; i < session.voters.length; i++) {
            emit VoteResultsDistributed(sessionId, session.voters[i], metadata);
        }
    }

    function isSessionFinalized(uint256 sessionId) external view returns (bool) {
        return sessions[sessionId].isFinalized;
    }

    //админ может закрыть конкретную сессию по дедлайну, не все
    function checkDeadline(uint256 sessionId) external {        
        VoteSession storage session = sessions[sessionId];
        require(!session.isFinalized, "Already finalized");
        require(block.timestamp > session.deadline, "Deadline not reached");
        _finalizeVote(sessionId);
    }

    //геттеры здесь и в других контраактах нужны больше для общности и тестов
    //в финальной версии тестов используются не все
    function getSessionYesVotes(uint256 sessionId) external view returns (uint256) {
        return sessions[sessionId].yesVotes;
    }

    function getSessionNoVotes(uint256 sessionId) external view returns (uint256) {
        return sessions[sessionId].noVotes;
    }

    function addAdmin(address account) external onlyRole(ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, account);
    }

    function removeAdmin(address account) external onlyOwner {
        _revokeRole(ADMIN_ROLE, account);
    }
}