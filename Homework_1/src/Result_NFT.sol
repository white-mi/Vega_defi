// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC721} from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {Base64} from "../lib/openzeppelin-contracts/contracts/utils/Base64.sol";

contract VoteResultNFT is ERC721, Ownable {
    using Strings for uint256;
    uint256 private _tokenIdCounter;
    mapping(uint256 => string) private _metadata;

    constructor(address initialOwner) ERC721("VoteResult", "VRNFT") Ownable(initialOwner) {}

    function mint(address to, string memory metadata) public {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        _metadata[tokenId] = metadata;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        return string(abi.encodePacked(
            "data:json;base64,",
            Base64.encode(bytes(_metadata[tokenId]))
        ));
    }
}
