// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Vault__NeedsToBeMoreThanZero();
    error Vault__TransferFailed();

    /*//////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IRebaseToken private immutable i_rebaseToken;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    modifier needsTobeMoreThanZero(uint256 amount){
        if (amount <= 0){
            revert Vault__NeedsToBeMoreThanZero();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(IRebaseToken rebaseToken) {
        i_rebaseToken = rebaseToken;
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                                 EXTERNALS
    //////////////////////////////////////////////////////////////*/

    function deposit() payable external needsTobeMoreThanZero(msg.value) {
        uint256 userInterestRate = i_rebaseToken.getInterestRate();
        i_rebaseToken.mint(msg.sender, msg.value, userInterestRate);
        emit Deposit(msg.sender, msg.value);
    }

    function redeem(uint256 amount) external needsTobeMoreThanZero(amount) {
        if (amount == type(uint256).max){
            amount = i_rebaseToken.balanceOf(msg.sender);
        }
        i_rebaseToken.burn(msg.sender, amount);
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success){
            revert Vault__TransferFailed();
        }
        emit Redeem(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getRebaseTokenAddress() external view returns (address){
        return address(i_rebaseToken);
    }
}