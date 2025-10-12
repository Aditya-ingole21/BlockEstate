// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PropertyNFT is ERC721, Ownable {
    uint256 public tokenCounter;
    mapping(uint256 => string) public propertyMetadata; // IPFS hash for metadata

    constructor() ERC721("BlockEstate", "BEST") Ownable(msg.sender) {
        tokenCounter = 0;
    }

    // Mint a new property NFT
    function mintProperty(address owner, string memory ipfsHash) public onlyOwner returns (uint256) {
        uint256 newTokenId = tokenCounter;
        _safeMint(owner, newTokenId);
        propertyMetadata[newTokenId] = ipfsHash;
        tokenCounter++;
        return newTokenId;
    }

    // Get metadata for a property
    function getPropertyMetadata(uint256 tokenId) public view returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return propertyMetadata[tokenId];
    }

    // Update metadata (e.g., for document updates)
    function updateMetadata(uint256 tokenId, string memory newIpfsHash) public onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        propertyMetadata[tokenId] = newIpfsHash;
    }
}
