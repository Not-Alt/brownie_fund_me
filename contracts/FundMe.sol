// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256; //for versions below 0.8.4

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        //to fund the contract !!!
        // uint256 minumumUSD = 50 * 10 ** 18;
        //require(getConversionRate(msg.value)>= minumumUSD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value; //matching the msg sender with the msg.sender and the new value of account
        // what is the eth/usd conversion rate?
        funders.push(msg.sender); //to see when a funder funds the contract and update then
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        //tuple
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 100000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        // return (minimumUSD * precision) / price;
        return ((minimumUSD * precision) / price) + 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance); //transfer can be called from any address to send eth from an address to another,
        // here we are sending eth to the msg.sender
        for (
            uint256 funderindex = 0;
            funderindex < funders.length;
            funderindex++
        ) {
            address funder = funders[funderindex]; // we are using funderindex as key in our mapping
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); //resetting the array after the withdrawal, funders = to a new blank address array
    }
}
