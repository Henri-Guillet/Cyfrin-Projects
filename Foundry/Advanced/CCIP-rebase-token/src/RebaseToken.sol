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

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {console2} from "forge-std/console2.sol";

/**
 * @title RebaseToken
 * @author Henri Guillet
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in rewards.
 * @notice The interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate that is the global interest rate at the time of depositing.
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error RebaseToken__InterestRateCanOnlyDecrease();

    /*//////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private s_interestRate = 5e10;
    mapping(address user => uint256) private s_userInterestRate;
    mapping(address user => uint256) private s_userLastUpdatedTimestamp;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event InterestRateSet(uint256 indexed newInterestRate);

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                                 EXTERNALS
    //////////////////////////////////////////////////////////////*/

    function grantMintAndBurnRole(address to) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, to);
    }

    /**
     * @notice Set the interest rate in the contract
     * @param newInterestRate The new interest rate to set
     * @dev The interest rate can only decrease
     */
    function setInterestRate(uint256 newInterestRate) external onlyOwner {
        if (newInterestRate > s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease();
        }
        s_interestRate = newInterestRate;
        emit InterestRateSet(newInterestRate);
    }

    /**
     * @notice Mints new tokens for a given address. Called when a user either deposits or bridges tokens to this chain.
     * @param to The address to mint the tokens to.
     * @param amount The number of tokens to mint.
     * @dev This function increases the total supply.
     */
    function mint(address to, uint256 amount, uint256 userInterestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(to);
        s_userInterestRate[to] = userInterestRate;
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from the sender.
     * @param account The address to burn the tokens from.
     * @param amount The amount of tokens to be burned
     */
    function burn(address account, uint256 amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(account);
        _burn(account, amount);
    }

    /**
     * @dev Transfers tokens from the sender to the recipient. This function also mints any accrued interest since the last time the user's balance was updated.
     * @param to The address of the recipient
     * @param amount The amount of tokens to transfer
     * @return True if the transfer was successful
     *
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(to);
        if (amount == type(uint256).max) {
            amount = balanceOf(msg.sender);
        }
        if (balanceOf(to) == 0) {
            // Update the users interest rate only if they have not yet got one (or they tranferred/burned all their tokens). Otherwise people could force others to have lower interest.
            s_userInterestRate[to] = s_userInterestRate[msg.sender];
        }
        return super.transfer(to, amount);
    }

    /**
     * @dev Transfers tokens from the sender to the recipient. This function also mints any accrued interest since the last time the user's balance was updated.
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param amount The amount of tokens to transfer
     * @return True if the transfer was successful
     *
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _mintAccruedInterest(from);
        _mintAccruedInterest(to);
        if (amount == type(uint256).max) {
            amount = balanceOf(from);
        }
        if (balanceOf(to) == 0) {
            // Update the users interest rate only if they have not yet got one (or they tranferred/burned all their tokens). Otherwise people could force others to have lower interest.
            s_userInterestRate[to] = s_userInterestRate[from];
        }
        return super.transferFrom(from, to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                 PRIVATE
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Accumulates the accrued interest of the user to the principal balance. This function mints the users accrued interest since they
     * last transferred or bridged tokens.
     * @param to the address of the user for which the interest is being minted
     *
     */
    function _mintAccruedInterest(address to) private {
        uint256 accruedInterest = _calculateUserAccumulatedInterestSinceLastUpdate(to);
        s_userLastUpdatedTimestamp[to] = block.timestamp;
        _mint(to, accruedInterest);
    }

    /**
     * @dev Returns the amount of interest accrued (in tokens) since the last time it was minted to the user.
     *
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address user) private view returns (uint256) {
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[user];
        return super.balanceOf(user) * s_userInterestRate[user] * timeElapsed / PRECISION_FACTOR;
    }

    /*//////////////////////////////////////////////////////////////
                                VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Returns the principal balance of the user. The principal balance is the last
     * updated stored balance, which does not consider the perpetually accruing interest that has not yet been minted.
     * @param user The address of the user
     * @return The principal balance of the user
     *
     */
    function principleBalanceOf(address user) external view returns (uint256) {
        return super.balanceOf(user);
    }

    /**
     * @dev Calculates the balance of the user, which is the
     * principal balance + interest generated by the principal balance
     * @param user The user for which the balance is being calculated
     * @return The total balance of the user
     */
    function balanceOf(address user) public view override returns (uint256) {
        uint256 accruedInterest = _calculateUserAccumulatedInterestSinceLastUpdate(user);
        return super.balanceOf(user) + accruedInterest;
    }

    function getUserInterestRate(address user) external view returns (uint256) {
        return s_userInterestRate[user];
    }

    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }
}
