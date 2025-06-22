// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { DeployFundMe } from "../../script/DeployFundMe.s.sol";
import { FundMe } from "../../src/FundMe.sol";
import { FundFundMe } from "../../script/Interactions.s.sol";

contract InteractionsTest is Test{
    FundMe public fundMe;

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function test_FundFundMe() public {
        //arrange
        FundFundMe fundFundMe = new FundFundMe();
        uint256 amountToFund = 0.1 ether;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.deal(msg.sender, 0.2 ether);
        fundFundMe.fundFundMe(address(fundMe));

        //assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, startingFundMeBalance + amountToFund);
    }

}
