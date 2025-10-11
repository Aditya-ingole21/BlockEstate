// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract ValuationOracle is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    uint256 public valuation;
    address private oracle;
    string private jobId;
    uint256 private fee;

    event ValuationReceived(uint256 valuation);

    constructor(address _linkToken, address _oracle, string memory _jobId, uint256 _fee) ConfirmedOwner(msg.sender) {
        setChainlinkToken(_linkToken);
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    // Request property valuation from external API
    function requestValuation(string memory apiUrl) public onlyOwner {
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(jobId), address(this), this.fulfill.selector);
        req.add("get", apiUrl);
        req.add("path", "valuation");
        sendChainlinkRequestTo(oracle, req, fee);
    }

    // Callback function for Chainlink
    function fulfill(bytes32 _requestId, uint256 _valuation) public recordChainlinkFulfillment(_requestId) {
        valuation = _valuation;
        emit ValuationReceived(_valuation);
    }

    // Utility function to convert string to bytes32
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}