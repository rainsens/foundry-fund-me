// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { PriceConverter } from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    // 5 USD in wei form
    uint256 public constant MINIMUM_USD = 5e18; // (5e10) or (5 * 1e18) or (5 * 10 ** 18)

    address[] private s_funders;

    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner; // an immutable variable can only be set once in constrctor

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        // constructor only executes once when the contract is deployed.
        // msg.sender is the address of the deployer
        i_owner = msg.sender; // as long as no other setter, this value will never change.
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, 
            "didn't send enough ETH"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        // in order to save gas
        // we put the length of s_funders to memory instead of storage.
        // then we only read the length from storage one.
        uint256 fundersLength = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        
        s_funders = new address[](0);

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");
    }

    function withdraw() public onlyOwner {

        // only the owner of this contract can call this function
        // so all the ethers in this contract will only be withdrawn to the owner of this contract

        // using modifier instead of below require.
        //require(msg.sender == owner, "Must be owner!");

        // 1.reset each user's funding amount in mapping to zero.
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        
        // 2.reset the array of funders.
        s_funders = new address[](0); // 0 length.
        
        /*
        "address" and "payable address":
        msg.sender = address
        payable(msg.sender) = payable address 
        // sending native blockchain token, can only work with payable address.

        3.withdraw the funds back to users who did the transaction previously.
        there are three different ways:
            1.transfer: simplest, throw errors, automatically revert.
            payable(msg.sender).transfer(address(this).balance);
            2.send: no throwing errors, return a boolean value.
            bool sendSuccess = payable(msg.sender).send(address(this).balance);
            3.call: powerful, can call any function in EVM without having an ABI.
            (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
        */

        // "call" is recommended.
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed!");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) { revert FundMe__NotOwner(); } // new syntax, gas efficient
        _;
    }

    // accidently call without calling the correct functions in this contract
    receive() external payable { 
        fund();
    }

    // accidently call without calling the correct functions in this contract
    fallback() external payable { 
        fund();
    }

    function getVersion() public view returns(uint256) {
        return s_priceFeed.version();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns(uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }
}