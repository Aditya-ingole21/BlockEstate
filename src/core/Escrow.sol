// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPropertyNFT.sol";

/// @title Escrow Contract for Real-Estate Transactions
/// @notice Holds buyer funds until NFT ownership is verified and approved
contract Escrow is Ownable, ReentrancyGuard {
    address public buyer;
    address public seller;
    uint256 public amount;
    bool public isFunded;
    bool public isApproved;
    bool public isCompleted;

    address public propertyNFT;
    uint256 public tokenId;

    // ---- Events ----
    event EscrowCreated(
        address indexed buyer,
        address indexed seller,
        address propertyNFT,
        uint256 tokenId
    );
    event Deposited(address indexed buyer, uint256 amount);
    event Approved(address indexed buyer);
    event FundsReleased(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    // ---- Constructor ----
    constructor(
        address _buyer,
        address _seller,
        address _propertyNFT,
        uint256 _tokenId
    ) Ownable() {
        require(_buyer != address(0), "Invalid buyer address");
        require(_seller != address(0), "Invalid seller address");
        require(_propertyNFT != address(0), "Invalid NFT address");
        require(_buyer != _seller, "Buyer and seller cannot be same");

        buyer = _buyer;
        seller = _seller;
        propertyNFT = _propertyNFT;
        tokenId = _tokenId;

        emit EscrowCreated(_buyer, _seller, _propertyNFT, _tokenId);
    }

    // ---- Core Functions ----

    /// @notice Buyer deposits ETH into escrow
    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(!isFunded, "Already funded");
        require(!isCompleted, "Escrow already completed");
        require(msg.value > 0, "Deposit must be > 0");

        amount = msg.value;
        isFunded = true;
        emit Deposited(buyer, amount);
    }

    /// @notice Buyer approves NFT and fund release
    function approve() external {
        require(msg.sender == buyer, "Only buyer can approve");
        require(isFunded, "Escrow not funded");
        require(!isApproved, "Already approved");

        isApproved = true;
        emit Approved(buyer);
    }

    /// @notice Platform/owner releases NFT & funds after buyer approval
    function releaseFunds() external onlyOwner nonReentrant {
        require(isApproved, "Not approved by buyer");
        require(isFunded, "Not funded");
        require(!isCompleted, "Escrow already completed");

        IPropertyNFT nftContract = IPropertyNFT(propertyNFT);

        // --- Safety checks ---
        require(nftContract.ownerOf(tokenId) == seller, "Seller not owner of NFT");
        require(
            nftContract.getApproved(tokenId) == address(this) ||
                nftContract.isApprovedForAll(seller, address(this)),
            "Escrow not approved to transfer NFT"
        );

        // --- Execute transfers ---
        nftContract.transferFrom(seller, buyer, tokenId);

        (bool success, ) = payable(seller).call{value: amount}("");
        require(success, "Fund transfer failed");

        isCompleted = true;
        emit FundsReleased(seller, amount);
    }

    /// @notice Refund buyer if transaction canceled
    function refund() external onlyOwner nonReentrant {
        require(isFunded, "Not funded");
        require(!isCompleted, "Escrow already completed");

        uint256 refundAmount = amount;

        isFunded = false;
        isApproved = false;
        isCompleted = true;
        amount = 0;

        (bool success, ) = payable(buyer).call{value: refundAmount}("");
        require(success, "Refund transfer failed");

        emit Refunded(buyer, refundAmount);
    }

    // ---- View Functions ----

    /// @notice Returns current state for UI/frontend
    function getEscrowState()
        external
        view
        returns (
            bool funded,
            bool approved,
            bool completed,
            uint256 escrowAmount,
            address escrowBuyer,
            address escrowSeller
        )
    {
        return (isFunded, isApproved, isCompleted, amount, buyer, seller);
    }

    // ---- Safety ----

    /// @notice Block direct ETH transfers
    receive() external payable {
        revert("Direct transfers not allowed");
    }

    fallback() external payable {
        revert("Fallback disabled");
    }
}
