// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/token/PropertyNFT.sol";

contract PropertyNFTTest is Test {
    PropertyNFT propertyNFT;
    address owner = address(0x1);
    address user = address(0x2);

    function setUp() public {
        vm.startPrank(owner);
        propertyNFT = new PropertyNFT();
        vm.stopPrank();
    }

    function testMintProperty() public {
        vm.startPrank(owner);
        uint256 tokenId = propertyNFT.mintProperty(user, "ipfs://test-hash");
        assertEq(tokenId, 0);
        assertEq(propertyNFT.ownerOf(0), user);
        assertEq(propertyNFT.getPropertyMetadata(0), "ipfs://test-hash");
        vm.stopPrank();
    }

    function testFailMintByNonOwner() public {
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        propertyNFT.mintProperty(user, "ipfs://test-hash");
        vm.stopPrank();
    }

    function testUpdateMetadata() public {
        vm.startPrank(owner);
        propertyNFT.mintProperty(user, "ipfs://test-hash");
        propertyNFT.updateMetadata(0, "ipfs://new-hash");
        assertEq(propertyNFT.getPropertyMetadata(0), "ipfs://new-hash");
        vm.stopPrank();
    }
}