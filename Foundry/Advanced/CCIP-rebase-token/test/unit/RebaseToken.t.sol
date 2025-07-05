// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {VaultDeployer} from "script/Deployers.s.sol";
import {RebaseTokenDeployer} from "script/Deployers.s.sol";
import {RebaseToken} from "src/RebaseToken.sol";
import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";
import {Vault} from "src/Vault.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract RebaseTokenTest is Test{

    RebaseToken private rebaseToken;
    Vault private vault;
    
    address private owner;
    address private user = makeAddr("user");

    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private constant PRECISION_FACTOR = 1e18;

    event InterestRateSet(uint256 indexed newInterestRate);
    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
  

    function setUp() public {
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        owner = rebaseToken.owner();
    }

    /*//////////////////////////////////////////////////////////////
                                 Helper functions
    //////////////////////////////////////////////////////////////*/
    function addRewards(uint256 amount) public {
        (bool success,) = payable(address(vault)).call{value: amount}("");
        require(success, "reward could not be added");
    }


    /*//////////////////////////////////////////////////////////////
                                 Modifiers
    //////////////////////////////////////////////////////////////*/
    modifier deposited (uint256 amount) {
        amount = bound(amount, 1, type(uint96).max);
        vm.prank(owner);
        rebaseToken.grantMintAndBurnRole(address(vault));
        vm.deal(user, amount);

        vm.prank(user);
        vault.deposit{value: amount}();
        _;
    }

     /*//////////////////////////////////////////////////////////////
                                 Tests
    //////////////////////////////////////////////////////////////*/ 
    function test_grantMintAndBurnRoleRevertsIfNotOwner(address to) public {
        vm.expectRevert(abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            user
        ));
        vm.prank(user);
        rebaseToken.grantMintAndBurnRole(to);
    }

    function test_grantsMintAndBurnRole(address to) public {
        vm.prank(owner);
        rebaseToken.grantMintAndBurnRole(to);
        bool hasRole = rebaseToken.hasRole(MINT_AND_BURN_ROLE, to);
        assertTrue(hasRole);
    }  




    /*//////////////////////////////////////////////////////////////
                                 Mint Tests
    //////////////////////////////////////////////////////////////*/
    function test_mintRevertsIfRoleNotMintAndBurn(address to, uint256 amount) public {
        uint256 interestRate = rebaseToken.getInterestRate();
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            owner,
            MINT_AND_BURN_ROLE
        ));
        rebaseToken.mint(to, amount, interestRate);
    }

    /*//////////////////////////////////////////////////////////////
                                 Deposit Tests
    //////////////////////////////////////////////////////////////*/
    function test_depositRevertsIfZero() public {
        vm.expectRevert(abi.encode(
            Vault.Vault__NeedsToBeMoreThanZero.selector
        ));
        vm.prank(user);
        vault.deposit{value: 0}();
    }

    function test_depositsFirstTimeAndReceivesExpectedAmount(uint256 amount) public {
        //Arrange
        amount = bound(amount, 1, type(uint96).max);
        vm.prank(owner);
        rebaseToken.grantMintAndBurnRole(address(vault));
        uint256 startingBalance = rebaseToken.balanceOf(user);
        vm.deal(user, amount);

        //Act
        vm.prank(user);
        vm.expectEmit(true, false, false, false, address(vault));
        emit Deposit(user, amount);
        vault.deposit{value: amount}();

        //Assert
        uint256 expectedBalance = startingBalance + amount;
        uint256 endingBalance = rebaseToken.balanceOf(user);
        assertEq(expectedBalance, endingBalance);
    }

    function test_depositsSecondTimeAndReceivesExpectedAmountIncludingInterests(
        uint256 amount,
        uint256 firstDepositAmount 
    ) 
        public 
        deposited(firstDepositAmount)
    {
        //Arrange
        amount = bound(amount, 1, type(uint96).max);
        uint256 startingBalance = rebaseToken.balanceOf(user);
        uint256 userInterestRate = rebaseToken.getUserInterestRate(user);
        vm.deal(user, amount);
        vm.warp(block.timestamp + 1 hours);

        //Act
        vm.prank(user);
        vault.deposit{value: amount}();

        //Assert
        uint256 expectedBalance = amount + startingBalance * (PRECISION_FACTOR + userInterestRate * 3600) / PRECISION_FACTOR;
        uint256 endingBalance = rebaseToken.balanceOf(user);
        assertEq(expectedBalance, endingBalance);
    }

    /*//////////////////////////////////////////////////////////////
                                 Burn Tests
    //////////////////////////////////////////////////////////////*/
    function test_bintRevertsIfRoleNotMintAndBurn(address to, uint256 amount) public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            owner,
            MINT_AND_BURN_ROLE
        ));
        rebaseToken.burn(to, amount);
    }
    /*//////////////////////////////////////////////////////////////
                                 Redeem Tests
    //////////////////////////////////////////////////////////////*/
    function test_redeemRevertsIfZero() public {
        vm.expectRevert(abi.encode(
            Vault.Vault__NeedsToBeMoreThanZero.selector
        ));
        vm.prank(user);
        vault.redeem(0);        
    }

    function test_redeemsAllAndReceivesExpectedAmount(uint256 firstDepositAmount) public deposited(firstDepositAmount){
        //Arrange
        uint256 startingEthBalance = user.balance;
        uint256 startingRbtBalance = rebaseToken.balanceOf(user);
        vm.warp(block.timestamp + 1 hours);
        uint256 rewards = rebaseToken.balanceOf(user) - rebaseToken.principleBalanceOf(user);//Add protocol rewards to the vault so interest can be paid
        addRewards(rewards);


        //Act
        vm.prank(user);
        vm.expectEmit(true, false, false, false, address(vault));
        emit Redeem(user, type(uint256).max);
        vault.redeem(type(uint256).max);

        //Assert
        uint256 endingEthBalance = user.balance;
        uint256 endingRbtBalance = rebaseToken.balanceOf(user);
        assertEq(endingEthBalance, startingEthBalance + startingRbtBalance + rewards);
        assertEq(endingRbtBalance, 0);
    }

    function test_redeemsPartiallyAndReceivesExpectedAmount(
        uint256 amount, 
        uint256 firstDepositAmount
    ) 
        public 
        deposited(firstDepositAmount)
    {
        //Arrange
        uint256 startingEthBalance = user.balance;
        uint256 startingRbtBalance = rebaseToken.balanceOf(user);
        amount = bound(amount, 1, startingRbtBalance);
        vm.warp(block.timestamp + 1 hours);
        uint256 rewards = rebaseToken.balanceOf(user) - rebaseToken.principleBalanceOf(user);//Add protocol rewards to the vault so interest can be paid
        addRewards(rewards);


        //Act
        vm.prank(user);
        vault.redeem(amount);

        //Assert
        uint256 endingEthBalance = user.balance;
        uint256 endingRbtBalance = rebaseToken.balanceOf(user);
        assertEq(endingEthBalance, startingEthBalance + amount);
        assertEq(endingRbtBalance, startingRbtBalance - amount + rewards);
    }    


    /*//////////////////////////////////////////////////////////////
                                 Interest Rate Tests
    //////////////////////////////////////////////////////////////*/
    function test_setInterestRateRevertsIfRateIsIncreasing(uint256 newInterestRate) public {
        uint256 interestRate = rebaseToken.getInterestRate();
        newInterestRate = bound(newInterestRate, interestRate + 1, type(uint256).max);
        vm.expectRevert(abi.encode(
            RebaseToken.RebaseToken__InterestRateCanOnlyDecrease.selector
        ));
        vm.prank(owner);
        rebaseToken.setInterestRate(newInterestRate);
    }

    function test_setInterestRateRevertsIfNotOwner(uint256 newInterestRate) public {
        vm.expectRevert(abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            user
        ));
        vm.prank(user);
        rebaseToken.setInterestRate(newInterestRate);
    }

    function test_setInterestRate(uint256 newInterestRate) public {
        uint256 interestRate = rebaseToken.getInterestRate();
        newInterestRate = bound(newInterestRate, 1, interestRate - 1);
        vm.expectEmit(true, false, false, false, address(rebaseToken));
        emit InterestRateSet(newInterestRate);
        vm.prank(owner);
        rebaseToken.setInterestRate(newInterestRate);
    }

    /*//////////////////////////////////////////////////////////////
                                 Transfer Tests
    //////////////////////////////////////////////////////////////*/
    function test_transferAllToNewUserAndCheckNewInterestRate(uint256 firstDepositAmount) public deposited(firstDepositAmount){
        //Arrange
        address user2 = makeAddr("user2");
        uint256 startingUserBalance = rebaseToken.balanceOf(user);
        vm.warp(block.timestamp + 1 hours);
        uint256 startingProtocolInterestRate = rebaseToken.getInterestRate();
        uint256 startingUserInterestRate = rebaseToken.getUserInterestRate(user);
        uint256 interest = (startingUserBalance * rebaseToken.getUserInterestRate(user) * 3600) / PRECISION_FACTOR;

        //Act
        vm.prank(owner);
        rebaseToken.setInterestRate(startingProtocolInterestRate / 2);
        vm.prank(user);
        rebaseToken.transfer(user2, type(uint256).max);

        //Assert
        uint256 endingUserBalance = rebaseToken.balanceOf(user);
        uint256 endingUser2Balance = rebaseToken.balanceOf(user2);
        uint256 user2InterestRate = rebaseToken.getUserInterestRate(user2);
        assertEq(endingUserBalance, 0);
        assertEq(endingUser2Balance, startingUserBalance + interest);
        assertEq(user2InterestRate, startingUserInterestRate);
    }

    function test_transferPartiallyToExistingUserAndCheckNewInterestRate(uint256 amount, uint256 firstDepositAmount) public deposited(firstDepositAmount){
        //Arrange
        uint256 startingUserBalance = rebaseToken.balanceOf(user);
        amount = bound(amount, 1, startingUserBalance);
        vm.warp(block.timestamp + 1 hours);
        //set new interest rate
        vm.startPrank(owner);
        rebaseToken.setInterestRate(rebaseToken.getInterestRate() / 2);
        vm.stopPrank();
        uint256 newInterestRate = rebaseToken.getInterestRate();
        //user2 deposits
        address user2 = makeAddr("user2");
        vm.deal(user2, 10 ether);
        vm.prank(user2);
        vault.deposit{value: 10 ether}();
        uint256 startingUser2Balance = rebaseToken.balanceOf(user2);

        //Act
        vm.prank(user);
        rebaseToken.transfer(user2, amount);

        //Assert
        uint256 interest = (startingUserBalance * rebaseToken.getUserInterestRate(user) * 3600) / PRECISION_FACTOR;
        uint256 endingUserBalance = rebaseToken.balanceOf(user);
        uint256 endingUser2Balance = rebaseToken.balanceOf(user2);
        uint256 user2InterestRate = rebaseToken.getUserInterestRate(user2);
        assertEq(endingUserBalance, startingUserBalance - amount + interest, "endingUserBalance");
        assertEq(endingUser2Balance, startingUser2Balance + amount, "endingUser2Balance");
        assertEq(user2InterestRate, newInterestRate, "userInterestRate");
    }

    /*//////////////////////////////////////////////////////////////
                                 TransferFrom Tests
    //////////////////////////////////////////////////////////////*/
    function test_transferFromAllToNewUserAndCheckNewInterestRate(uint256 firstDepositAmount) public deposited(firstDepositAmount){
        //Arrange
        address user2 = makeAddr("user2");
        uint256 startingUserBalance = rebaseToken.balanceOf(user);
        vm.warp(block.timestamp + 1 hours);
        uint256 startingProtocolInterestRate = rebaseToken.getInterestRate();
        uint256 startingUserInterestRate = rebaseToken.getUserInterestRate(user);
        uint256 interest = (startingUserBalance * rebaseToken.getUserInterestRate(user) * 3600) / PRECISION_FACTOR;

        //Act
        vm.prank(owner);
        rebaseToken.setInterestRate(startingProtocolInterestRate / 2);
        vm.prank(user);
        rebaseToken.approve(address(rebaseToken), type(uint256).max);
        vm.prank(address(rebaseToken));
        rebaseToken.transferFrom(user, user2, type(uint256).max);

        //Assert
        uint256 endingUserBalance = rebaseToken.balanceOf(user);
        uint256 endingUser2Balance = rebaseToken.balanceOf(user2);
        uint256 user2InterestRate = rebaseToken.getUserInterestRate(user2);
        assertEq(endingUserBalance, 0);
        assertEq(endingUser2Balance, startingUserBalance + interest);
        assertEq(user2InterestRate, startingUserInterestRate);
    }

    function test_transferFromPartiallyToExistingUserAndCheckNewInterestRate(uint256 amount, uint256 firstDepositAmount) public deposited(firstDepositAmount){
        //Arrange
        uint256 startingUserBalance = rebaseToken.balanceOf(user);
        amount = bound(amount, 1, startingUserBalance);
        vm.warp(block.timestamp + 1 hours);
        //set new interest rate
        vm.startPrank(owner);
        rebaseToken.setInterestRate(rebaseToken.getInterestRate() / 2);
        vm.stopPrank();
        uint256 newInterestRate = rebaseToken.getInterestRate();
        //user2 deposits
        address user2 = makeAddr("user2");
        vm.deal(user2, 10 ether);
        vm.prank(user2);
        vault.deposit{value: 10 ether}();
        uint256 startingUser2Balance = rebaseToken.balanceOf(user2);

        //Act
        vm.prank(user);
        rebaseToken.approve(address(rebaseToken), amount);
        vm.prank(address(rebaseToken));
        rebaseToken.transferFrom(user, user2, amount);

        //Assert
        uint256 interest = (startingUserBalance * rebaseToken.getUserInterestRate(user) * 3600) / PRECISION_FACTOR;
        uint256 endingUserBalance = rebaseToken.balanceOf(user);
        uint256 endingUser2Balance = rebaseToken.balanceOf(user2);
        uint256 user2InterestRate = rebaseToken.getUserInterestRate(user2);
        assertEq(endingUserBalance, startingUserBalance - amount + interest, "endingUserBalance");
        assertEq(endingUser2Balance, startingUser2Balance + amount, "endingUser2Balance");
        assertEq(user2InterestRate, newInterestRate, "userInterestRate");
    }
    /*//////////////////////////////////////////////////////////////
                                 Getters Tests
    //////////////////////////////////////////////////////////////*/
    function test_getRebaseTokenAddress() public view {
        address rebaseTokenAddress = vault.getRebaseTokenAddress();
        assertEq(rebaseTokenAddress, address(rebaseToken));
    }

}