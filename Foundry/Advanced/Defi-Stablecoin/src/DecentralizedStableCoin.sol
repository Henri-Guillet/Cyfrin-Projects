// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
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

pragma solidity ^0.8.28;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @title DecentralizedStableCoin
 * @author Henri Guillet
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 *
* This is the contract meant to be owned by DSCEngine. It is a ERC20 token that can be minted and burned by the
DSCEngine smart contract.
 */
contract DecentralizedStableCoin is ERC20Burnable, Ownable {

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error DecentralizedStableCoin__MoreThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();
    error DecentralizedStableCoin__NotZeroAddress();

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20("DecentralizedStableCOin", "DSC") Ownable(msg.sender){}

    function burn(uint256 amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (amount <= 0){
            revert DecentralizedStableCoin__MoreThanZero();
        }
        if (balance < amount){
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(amount);
    }

    function mint(address _to, uint256 amount) external onlyOwner returns(bool) {
        if (_to == address(0)){
            revert DecentralizedStableCoin__NotZeroAddress();
        }
        if (amount <= 0){
            revert DecentralizedStableCoin__MoreThanZero();
        }
        _mint(_to, amount);
        return true;
    }

}