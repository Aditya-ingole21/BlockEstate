// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/ValuationOracle.sol";

contract DeployValuation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        address linkToken = vm.envAddress("LINK_TOKEN");
        address oracle = vm.envAddress("CHAINLINK_ORACLE");
        string memory jobId = vm.envString("JOB_ID");
        uint256 fee = 0.1 ether;
        
        ValuationOracle valuationOracle = new ValuationOracle(
            linkToken,
            oracle,
            jobId,
            fee
        );
        
        console.log("ValuationOracle deployed at:", address(valuationOracle));
        
        vm.stopBroadcast();
    }
}