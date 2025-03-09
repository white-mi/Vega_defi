// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {VotingSystem} from "../src/Voting.sol";
import {VegaVoteToken} from "../src/VegaVoteToken.sol";
import {Staking} from "../src/Stacking.sol";
import {VoteResultNFT} from "../src/Result_NFT.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        VegaVoteToken token = new VegaVoteToken();
        Stake stake = new Stake(address(token));
        VoteResult nft = new VoteResult(deployerAddress);
        Voting voting = new Voting(address(stake), deployerAddress, address(nft));

        vm.stopBroadcast();

        console.log("VegaVoteToken address is ", address(token));
        console.log("Stake address is ", address(stake));
        console.log("VoteResult address is ", address(nft));
        console.log("Voting address is ", address(voting));
    }
}