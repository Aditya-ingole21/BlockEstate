// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/token/PropertyNFT.sol";

contract PropertyNFTTest is Test {
    PropertyNFT nft;
    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        nft = new PropertyNFT();
    }

    function test_OwnerCanMint() public {
        uint256 newTokenId = nft.mintProperty(user1, "ipfs://hash1");
        assertEq(newTokenId, 0);
        assertEq(nft.ownerOf(newTokenId), user1);
        assertEq(nft.getPropertyMetadata(newTokenId), "ipfs://hash1");
        assertEq(nft.tokenCounter(), 1);
    }

    function test_RevertWhen_NonOwnerMints() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.mintProperty(user1, "ipfs://hash1");
    }

    function test_OwnerCanUpdateMetadata() public {
        uint256 tokenId = nft.mintProperty(user1, "ipfs://hash1");
        nft.updateMetadata(tokenId, "ipfs://hash2");
        assertEq(nft.getPropertyMetadata(tokenId), "ipfs://hash2");
    }

    function test_RevertWhen_UpdateNonexistentToken() public {
        vm.expectRevert("Token does not exist");
        nft.updateMetadata(999, "ipfs://newHash");
    }

    function test_RevertWhen_GetMetadataNonexistentToken() public {
        vm.expectRevert("Token does not exist");
        nft.getPropertyMetadata(999);
    }

    function test_TokenCounterIncrements() public {
        nft.mintProperty(user1, "ipfs://hash1");
        nft.mintProperty(user2, "ipfs://hash2");
        nft.mintProperty(user1, "ipfs://hash3");
        assertEq(nft.tokenCounter(), 3);
    }

    function test_CanTransferNFT() public {
        uint256 tokenId = nft.mintProperty(user1, "ipfs://hash1");
        vm.prank(user1);
        nft.transferFrom(user1, user2, tokenId);
        assertEq(nft.ownerOf(tokenId), user2);
    }
}