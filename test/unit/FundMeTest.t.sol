// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { FundMe } from "../../src/FundMe.sol";
import { DeployFundMe } from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("USER"); // fake user for testing
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000 wei
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1; // pretend using real gas price

    function setUp() external {
        // In this way, we maybe forget to deploy before running tests.
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        // Instead this way, we can make sure we always deploy before testing.
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // give 10 ether to test USER
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        //assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // assert the next line will revert.
        // fundMe.fund{value: 10e18}(); // send 10 eth
        fundMe.fund(); // send 0 value of wei/eth
    }

    function testFundUpdatesFundedDataStructure() public {
        // It's hard to know who is sending the transaction
        // so we use prank here to simulate the sender.
        vm.prank(USER); // the next transaction will be sent by fake USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER); // USER = msg.sender
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); // the following transaction will be sent by fake USER
        vm.expectRevert(); // assert the next line will revert.
        fundMe.withdraw(); // USER is not the owner of the contract
    }

    function testWithdrawWithASingleFunder() public funded {
        // Whenever working with a test, always think of it mentally in this pattern
        
        // Arrange
        // balance belongs to the owner of the contract after first transaction sent
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // balance only belongs to the contract after first transaction sent
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        console.log("startingOwnerBalance: ", startingOwnerBalance);
        console.log("startingFundMeBalance: ", startingFundMeBalance);

        // Act
        uint256 gasStart = gasleft();
        vm.prank(fundMe.getOwner());
        vm.txGasPrice(GAS_PRICE); // pretend using real gas price
        fundMe.withdraw(); // withdraw balance from contract to the owner of the contract
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gasUsed: ", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        console.log("endingOwnerBalance: ", endingOwnerBalance);
        console.log("endingFundMeBalance: ", endingFundMeBalance);

        assert(endingFundMeBalance == 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance, 
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        // As of Solidity 0.8, no longer cast explicitly from address to uint256
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        
        // simulate multiple funders funded the contract
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank()
            // vm.deal()
            // hoax does both vm.prank and vm.deal in one step
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();  // withdraw balance from contract to the owner of the contract
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance, 
            fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        // As of Solidity 0.8, no longer cast explicitly from address to uint256
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        
        // simulate multiple funders funded the contract
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank()
            // vm.deal()
            // hoax does both vm.prank and vm.deal in one step
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        // withdraw balance from contract to the owner of the contract
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance, 
            fundMe.getOwner().balance
        );
    }
}