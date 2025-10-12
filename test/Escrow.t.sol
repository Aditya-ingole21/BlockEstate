// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/Escrow.sol";
import "../src/token/PropertyNFT.sol";

contract EscrowTest is Test {
    PropertyNFT nft;
    Escrow escrow;

    address buyer = address(0xBEEF);
    address seller = address(0xCAFE);
    address platform = address(this); // Escrow owner
    uint256 tokenId;

    function setUp() public {
        // Deploy NFT contract and mint a property to the seller
        nft = new PropertyNFT();
        tokenId = nft.mintProperty(seller, "ipfs://property1");

        // Deploy Escrow contract (owner = this test contract)
        escrow = new Escrow(buyer, seller, address(nft), tokenId);
    }

    /// @notice Buyer can deposit funds into escrow
    function testBuyerCanDeposit() public {
        uint256 depositAmount = 1 ether;
        vm.deal(buyer, depositAmount);

        vm.prank(buyer);
        escrow.deposit{value: depositAmount}();

        assertEq(escrow.amount(), depositAmount);
        assertTrue(escrow.isFunded());
    }

    /// @notice Non-buyer should not be able to deposit
    function test_RevertIf_NonBuyerDeposits() public {
        vm.expectRevert("Only buyer can deposit");
        escrow.deposit{value: 1 ether}();
    }

     function test_RevertIf_DepositTwice() public {
        uint256 depositAmount = 1 ether;
        vm.deal(buyer, 2 ether);

        // First deposit should work
        vm.prank(buyer);
        escrow.deposit{value: depositAmount}();

        // Second deposit should revert
        vm.prank(buyer);
        vm.expectRevert("Already funded");
        escrow.deposit{value: depositAmount}();
    }

    /// @notice Buyer can approve after funding
    function testBuyerCanApprove() public {
        uint256 depositAmount = 1 ether;
        vm.deal(buyer, depositAmount);

        vm.prank(buyer);
        escrow.deposit{value: depositAmount}();

        vm.prank(buyer);
        escrow.approve();

        assertTrue(escrow.isApproved());
    }

    /// @notice Only buyer can approve
    function test_RevertIf_NonBuyerApproves() public {
        vm.expectRevert("Only buyer can approve");
        escrow.approve();
    }

    /// @notice Should revert if releasing without buyer approval
    function test_RevertIf_ReleaseWithoutApproval() public {
        uint256 depositAmount = 1 ether;
        vm.deal(buyer, depositAmount);

        vm.prank(buyer);
        escrow.deposit{value: depositAmount}();

        vm.expectRevert("Not approved by buyer");
        escrow.releaseFunds();
    }

    /// @notice Full flow: deposit, approve, transfer NFT, and release funds
    function testReleaseFundsSuccess() public {
        uint256 depositAmount = 1 ether;
        vm.deal(buyer, depositAmount);

        // Buyer deposits
        vm.prank(buyer);
        escrow.deposit{value: depositAmount}();

        // Buyer approves
        vm.prank(buyer);
        escrow.approve();

        // Seller approves NFT for Escrow
        vm.prank(seller);
        nft.approve(address(escrow), tokenId);

        uint256 sellerBalanceBefore = seller.balance;

        // Platform (owner) releases funds
        escrow.releaseFunds();

        uint256 sellerBalanceAfter = seller.balance;

        // NFT transferred to buyer
        assertEq(nft.ownerOf(tokenId), buyer);
        // ETH transferred to seller
        assertEq(sellerBalanceAfter - sellerBalanceBefore, depositAmount);
        // Escrow completed
        assertTrue(escrow.isCompleted());
    }

    /// @notice Refund should send back buyer's funds
    function testRefundSuccess() public {
        uint256 depositAmount = 1 ether;
        vm.deal(buyer, depositAmount);

        // Buyer deposits
        vm.prank(buyer);
        escrow.deposit{value: depositAmount}();

        uint256 buyerBalanceBefore = buyer.balance;
        escrow.refund();
        uint256 buyerBalanceAfter = buyer.balance;

        assertApproxEqAbs(buyerBalanceAfter, buyerBalanceBefore + depositAmount, 1);
        assertTrue(escrow.isCompleted());
    }

    /// @notice Refund should revert if not funded
    function test_RevertIf_RefundWithoutFunds() public {
        vm.expectRevert("Not funded");
        escrow.refund();
    }

    /// @notice Release should fail if NFT not approved
    function test_RevertIf_NFTNotApproved() public {
        uint256 depositAmount = 1 ether;
        vm.deal(buyer, depositAmount);

        vm.prank(buyer);
        escrow.deposit{value: depositAmount}();

        vm.prank(buyer);
        escrow.approve();

        vm.expectRevert("Escrow not approved to transfer NFT");
        escrow.releaseFunds();
    }
}
