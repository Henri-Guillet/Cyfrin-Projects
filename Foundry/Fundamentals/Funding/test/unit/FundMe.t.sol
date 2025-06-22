// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { DeployFundMe } from "../../script/DeployFundMe.s.sol";
import { FundMe } from "../../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe public fundMe;
    address public user = makeAddr("user");

    function setUp() public {
        DeployFundMe deployFundMeScript = new DeployFundMe();
        fundMe = deployFundMeScript.run();
    }

    function test_MinimumDollarIsFive() public view {
        uint256 minimum = fundMe.MINIMUM_USD();
        assertEq(minimum, 5e18);
    }

    function test_OwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function test_MinimumFundingAmount() public {
        vm.prank(user);
        vm.deal(user, 1 ether);
        vm.expectRevert("You need to spend more ETH!");
        fundMe.fund{value: 1}();
    }

    function test_AddressIsFunded() public {
        vm.prank(user);
        vm.deal(user, 1 ether);
        fundMe.fund{value: 0.1 ether}();
        uint256 s_addressToAmountFunded = fundMe.getAddressToAmountFunded(user);
        assertEq(s_addressToAmountFunded, 0.1 ether);
    }

    function test_FunderIsRegistered() public {
        vm.prank(user);
        vm.deal(user, 1 ether);
        fundMe.fund{value: 0.1 ether}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, user);
    }

    function test_WithdrawNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        fundMe.withdraw();
    }

    // function test_WithdrawFailed() public {
    //     vm.prank(msg.sender);
    //     vm.expectRevert();
    //     fundMe.withdraw();
    // }

    function test_OwnerCanWithdraw() public{
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        vm.prank(user);
        vm.deal(user, 1 ether);
        fundMe.fund{value: 0.1 ether}();

        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingOwnerBalance, startingOwnerBalance + 0.1 ether + startingFundMeBalance);    
    }

    function test_WithdrawMultipleFundings() public {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i <= numberOfFunders; i++){
            hoax(address(i), 1 ether);
            fundMe.fund{value: 0.1 ether}();
        }

        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingOwnerBalance, startingOwnerBalance + uint256(numberOfFunders)*0.1 ether + startingFundMeBalance);    
    }


    function test_CheaperWithdrawNotOwner() public {
        vm.prank(user);
        vm.expectRevert();
        fundMe.withdraw();
    }


    function test_OwnerCanCheaperWithdraw() public{
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act
        vm.prank(user);
        vm.deal(user, 1 ether);
        fundMe.fund{value: 0.1 ether}();
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingOwnerBalance, startingOwnerBalance + 0.1 ether + startingFundMeBalance);    
    }

    function test_Version() public view {
        uint256 version = fundMe.getVersion();
        assertGe(version, 0);
    }
}