// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/token/PropertyNFT.sol";
import "../src/core/ValuationOracle.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy PropertyNFT
        PropertyNFT nft = new PropertyNFT();
        console.log("PropertyNFT deployed at:", address(nft));
        
        // Deploy ValuationOracle
        address linkToken = vm.envAddress("LINK_TOKEN");
        address chainlinkOracle = vm.envAddress("CHAINLINK_ORACLE");
        string memory jobId = vm.envString("JOB_ID");
        
        ValuationOracle valuationOracle = new ValuationOracle(
            linkToken,
            chainlinkOracle,
            jobId,
            0.1 ether
        );
        console.log("ValuationOracle deployed at:", address(valuationOracle));
        
        // Mint some test NFTs
        address testUser1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Test account
        nft.mintProperty(testUser1, "ipfs://QmTest1");
        nft.mintProperty(testUser1, "ipfs://QmTest2");
        console.log("Minted 2 test NFTs to:", testUser1);
        
        vm.stopBroadcast();
    }
}