// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {VotingSystem} from "../src/Voting.sol";
import {Staking} from "../src/Staking.sol";
import {VoteResultNFT} from "../src/Result_NFT.sol";

contract DeploySepolia is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address erc20 = vm.envAddress("ERC20_ADDRESS");
        vm.startBroadcast(deployerKey);
        VoteResultNFT nft = new VoteResultNFT(msg.sender);
        Staking staking = new Staking(erc20);
        VotingSystem voting = new VotingSystem(msg.sender,address(staking), address(nft));

        vm.stopBroadcast();
    }
}