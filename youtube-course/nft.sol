// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DevTry is ERC721, Ownable {
    uint256 private _nextTokenId;
    uint256 private _price;
    uint256 private _maxSupply;

    constructor(address initialOwner, uint256 price, uint256 maxSupply)
        ERC721("DevTry", "DTR")
        Ownable(initialOwner)
    {
        _price = price;
        _maxSupply = maxSupply;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://i.pinimg.com/736x/e1/83/82/e183829d60410dc61d7b41b3362e4e01.jpg";
    }

    function safeMint(address to) public onlyOwner returns (uint256) {
        require(_nextTokenId < _maxSupply, "max supply exceeded");
        require(super.balanceOf(to) == 0, "user already have NFT");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function buy() public payable returns (uint256) {
        require(_nextTokenId < _maxSupply, "max supply exceeded");
        require(msg.value >= _price, "not enough founds");
        require(super.balanceOf(msg.sender) == 0, "user already have NFT");

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "nothing to withdraw");
        payable(owner()).transfer(balance);
    }
}
