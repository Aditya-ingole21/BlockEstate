// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/Escrow.sol";
import "../src/token/PropertyNFT.sol";

contract EscrowTest is Test {
    PropertyNFT propertyNFT;
    Escrow escrow;
    address owner = address(0x1);
    address buyer = address(0x2);
    address seller = address(0x3);

    function setUp() public {
        vm.startPrank(owner);
        propertyNFT = new PropertyNFT();
        propertyNFT.mintProperty(seller, "ipfs://test-hash");
        escrow = new Escrow(buyer, seller, address(propertyNFT), 0);
        vm.stopPrank();
    }

    function testDeposit() public {
        vm.deal(buyer, 1 ether);
        vm.startPrank(buyer);
        escrow.deposit{value: 1 ether}();
        assertEq(escrow.isFunded(), true);
        assertEq(escrow.amount(), 1 ether);
        vm.stopPrank();
    }

    function testFailDepositByNonBuyer() public {
        vm.startPrank(seller);
        vm.expectRevert("Only buyer can deposit");
        escrow.deposit{value: 1 ether}();
        vm.stopPrank();
    }

    function testReleaseFunds() public {
        vm.deal(buyer, 1 ether);
        vm.startPrank(buyer);
        escrow.deposit{value: 1 ether}();
        escrow.approve();
        vm.stopPrank();
        vm.startPrank(owner);
        uint256 sellerBalanceBefore = seller.balance;
        escrow.releaseFunds();
        assertEq(seller.balance, sellerBalanceBefore + 1 ether);
        assertEq(propertyNFT.ownerOf(0), buyer);
        vm.stopPrank();
    }
}