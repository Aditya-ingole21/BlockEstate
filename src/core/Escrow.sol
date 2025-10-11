// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPropertyNFT.sol";  // Import the interface

contract Escrow is Ownable {
    address public buyer;
    address public seller;
    uint256 public amount;
    bool public isFunded;
    bool public isApproved;
    address public propertyNFT;
    uint256 public tokenId;

    event Deposited(address indexed buyer, uint256 amount);
    event Approved(address indexed buyer);
    event FundsReleased(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    constructor(address _buyer, address _seller, address _propertyNFT, uint256 _tokenId) Ownable(msg.sender) {
        buyer = _buyer;
        seller = _seller;
        propertyNFT = _propertyNFT;
        tokenId = _tokenId;
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(!isFunded, "Already funded");
        amount = msg.value;
        isFunded = true;
        emit Deposited(buyer, amount);
    }

    function approve() external {
        require(msg.sender == buyer, "Only buyer can approve");
        require(isFunded, "Escrow not funded");
        isApproved = true;
        emit Approved(buyer);
    }

    function releaseFunds() external onlyOwner {
        require(isApproved, "Not approved");
        require(isFunded, "Not funded");
        
        IPropertyNFT nftContract = IPropertyNFT(propertyNFT);  // Use the imported interface
        require(nftContract.ownerOf(tokenId) == seller, "Seller does not own NFT");
        nftContract.transferFrom(seller, buyer, tokenId);
        
        payable(seller).transfer(amount);
        emit FundsReleased(seller, amount);
    }

    function refund() external onlyOwner {
        require(isFunded, "Not funded");
        payable(buyer).transfer(amount);
        isFunded = false;
        emit Refunded(buyer, amount);
    }
}