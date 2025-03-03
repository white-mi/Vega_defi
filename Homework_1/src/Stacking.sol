// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {VegaVoteToken} from "src/VegaVoteToken.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 period;
        bool isWithdrawn;
    }

    VegaVoteToken public token;
    mapping(address => Stake[]) public stakes;

    constructor(address _token) {
        token = VegaVoteToken(_token);
    }

    function stake(uint256 amount, uint256 period) external nonReentrant {
        require(period <= 4 * 365 days, "Max 4 years");
        token.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender].push(Stake(amount, block.timestamp, period, false));
    }

    //для простоты проверяю, что человек может вернуть свои стейки по индексам
    //то есть без общей денежной массы
    function unstake(uint256 stakeIndex) external nonReentrant {
        require(stakeIndex < stakes[msg.sender].length, "Invalid index of stake");
        Stake storage stakeInfo = stakes[msg.sender][stakeIndex];
        require(!stakeInfo.isWithdrawn, "Stake with this index is already withdrawn");
        require(
            block.timestamp >= stakeInfo.startTime + stakeInfo.period,
            "Period of stake with this index is not ended. Please, return later."
        );
        stakeInfo.isWithdrawn = true;
        token.transfer(msg.sender, stakeInfo.amount);
    }

    function calculateVotingPower(address user) public view returns (uint256) {
        uint256 totalPower;
        for (uint256 i = 0; i < stakes[user].length; i++) {
            Stake memory s = stakes[user][i];
            if (!s.isWithdrawn && block.timestamp < s.startTime + s.period) {
                totalPower += s.amount * (s.period ** 2);
            }
        }
        return totalPower;
    }

    function getStakeInfo(address user, uint256 stakeIndex)
        external
        view
        returns (uint256 amount, uint256 startTime, uint256 period, bool isWithdrawn)
    {
        require(stakeIndex < stakes[user].length, "Invalid index of stake");
        Stake memory stakeInfo = stakes[user][stakeIndex];
        return (stakeInfo.amount, stakeInfo.startTime, stakeInfo.period, stakeInfo.isWithdrawn);
    }
}
