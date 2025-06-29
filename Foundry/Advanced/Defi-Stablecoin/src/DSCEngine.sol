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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {console2} from "forge-std/console2.sol";
import {OracleLib} from "./librairies/OracleLib.sol";

/*
 * @title DSCEngine
 * @author Henri Guillet
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */
contract DSCEngine is ReentrancyGuard{
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error DSCEngine__BalanceTooLow();
    error DSCEngine__TransferFailed();
    error DSCEngine__MoreThanZero();
    error DSCEngine__TokenNotAllowed();
    error DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__HealthFactorBroken();
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorIsOk();

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    using OracleLib for AggregatorV3Interface;

    /*//////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    DecentralizedStableCoin private immutable i_dsc;

    uint256 private constant LIQUIDATION_THRESHOLD = 50; //50% meaning one needs to have twice as much collateral relative to borrow
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10;
    uint256 private constant FEED_PRECISION = 1e8;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;

    mapping(address user => mapping(address token => uint256 balance)) private s_collateralDeposited;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => uint256) private s_dscMinted;
    address[] private s_collateralTokens;


    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed from,address indexed to, address tokenCollateralAddress, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier moreThanZero(uint256 amount) {
        if (amount <= 0) {
            revert DSCEngine__MoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)){
            revert DSCEngine__TokenNotAllowed();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(
        address dscToken, 
        address[] memory tokens, 
        address[] memory priceFeeds
    ) {
        if(tokens.length != priceFeeds.length){
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokens.length; i++){
            s_priceFeeds[tokens[i]] = priceFeeds[i];
        }
        i_dsc = DecentralizedStableCoin(dscToken);
        s_collateralTokens = tokens;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountToDeposit: The amount of collateral you're depositing
     * @param amountToMint: The amount of DSC you want to mint
     * @notice This function will deposit your collateral and mint DSC in one transaction
     */
    function depositCollateralAndMintDsc(
        uint256 amountToDeposit, 
        address tokenCollateralAddress, 
        uint256 amountToMint
    ) 
        external 
    {
        depositCollateral(amountToDeposit, tokenCollateralAddress);
        mintDsc(amountToMint);
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're redeeming
     * @param amount: The amount of collateral you're redeeming
     * @notice This function will redeem your collateral.
     * @notice If you have DSC minted, you will not be able to redeem until you burn your DSC
     */
    function redeemCollateral(
        uint256 amount, 
        address tokenCollateralAddress
    ) 
        external 
    {
        _redeemCollateral(amount, tokenCollateralAddress, msg.sender, msg.sender);
    }

   function burnDsc(uint256 amount) external {
        _burnDsc(amount, msg.sender, msg.sender);
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're withdrawing
     * @param amountToRedeem: The amount of collateral you're withdrawing
     * @param dscToBurn: The amount of DSC you want to burn
     * @notice This function will withdraw your collateral and burn DSC in one transaction
     */
    function redeemCollateralForDsc(
        uint256 amountToRedeem, 
        address tokenCollateralAddress, 
        uint256 dscToBurn
    ) 
        external 
    {
        _burnDsc(dscToBurn, msg.sender, msg.sender);
        _redeemCollateral(amountToRedeem, tokenCollateralAddress, msg.sender, msg.sender);
    }

    /*
     * @param collateral: The ERC20 token address of the collateral you're using to make the protocol solvent again.
     * This is collateral that you're going to take from the user who is insolvent.
     * In return, you have to burn your DSC to pay off their debt, but you don't pay off your own.
     * @param user: The user who is insolvent. They have to have a _healthFactor below MIN_HEALTH_FACTOR
     * @param debtToCover: The amount of DSC you want to burn to cover the user's debt.
     *
     * @notice: You can partially liquidate a user.
     * @notice: You will get a 10% LIQUIDATION_BONUS for taking the users funds.
     * @notice: This function working assumes that the protocol will be roughly 150% overcollateralized in order for this
    to work.
     * @notice: A known bug would be if the protocol was only 100% collateralized, we wouldn't be able to liquidate
    anyone.
     * For example, if the price of the collateral plummeted before anyone could be liquidated.
     */
    function liquidate(
        address collateral, 
        address user, 
        uint256 debtToCover
    ) 
        external 
    {
        if(_getHealthFactor(user) >= MIN_HEALTH_FACTOR){
            revert DSCEngine__HealthFactorIsOk();
        }
        _burnDsc(debtToCover, user, msg.sender);
        uint256 collateralToReceive = _getTokenAmountFromUsd(collateral, debtToCover);
        collateralToReceive =  collateralToReceive * (LIQUIDATION_PRECISION + LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        _redeemCollateral(collateralToReceive, collateral, user, msg.sender);
    }


    /*//////////////////////////////////////////////////////////////
                                PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amount: The amount of collateral you're depositing
     */    
    function depositCollateral(
        uint256 amount,
        address tokenCollateralAddress
    ) 
        public 
        moreThanZero(amount)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant 
    {
        uint256 balance = IERC20(tokenCollateralAddress).balanceOf(msg.sender);
        if (balance < amount) {
            revert DSCEngine__BalanceTooLow();
        }
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amount;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amount);
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }


    /**
     * 
     * @param amount The amount of decentralized stablecoin to mint
     * @notice Amount needs to be > 0
     */
    function mintDsc(uint256 amount) public moreThanZero(amount) nonReentrant {
        s_dscMinted[msg.sender] += amount;
        _revertIfHealthFactorBroken(msg.sender);
        bool success = i_dsc.mint(msg.sender, amount);
        if(!success){
            revert DSCEngine__MintFailed();
        }
    }




    /*//////////////////////////////////////////////////////////////
                                PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _burnDsc(
        uint256 amount, 
        address debtor, 
        address payer
    ) 
        private 
        moreThanZero(amount) 
        nonReentrant 
    {
        s_dscMinted[debtor] -= amount;
        bool success = IERC20(i_dsc).transferFrom(payer, address(this), amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function _redeemCollateral(
        uint256 amount, 
        address tokenCollateralAddress,
        address from,
        address to
    ) 
        private 
        moreThanZero(amount) 
        nonReentrant 
        isAllowedToken(tokenCollateralAddress) 
    {
        s_collateralDeposited[from][tokenCollateralAddress] -= amount;
        _revertIfHealthFactorBroken(from);
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amount);
        bool success = IERC20(tokenCollateralAddress).transfer(to, amount);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                                PRIVATE VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _getAccountInformation(address user) 
        private 
        view 
        returns(uint256 totalCollateralUsd, uint256 totalBorrow)
    {
        totalBorrow = s_dscMinted[user];
        totalCollateralUsd = _getAccountCollateralValue(user);
    }

    function _getAccountCollateralValue(address user) public view returns(uint256 totalCollateralUsd){
        for(uint256 i = 0; i < s_collateralTokens.length; i++){
            address token = s_collateralTokens[i];
            uint256 balance = s_collateralDeposited[user][token];
            totalCollateralUsd += _getUsdValue(token, balance);
        }
        return totalCollateralUsd;
    }

    function _getUsdValue(address token, uint256 amount) private view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        return (amount * uint256(price) * ADDITIONAL_FEED_PRECISION) / PRECISION;
    }

    function _getTokenAmountFromUsd(address token, uint256 usdAmount) private view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.staleCheckLatestRoundData();
        uint256 tokenAmount = (usdAmount * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION) ;
        return tokenAmount;        
    }

    function _revertIfHealthFactorBroken(address user) private view {
        uint256 healthFactor = _getHealthFactor(user);
        if (healthFactor < MIN_HEALTH_FACTOR){
            revert DSCEngine__HealthFactorBroken();
        }
    }

    function _getHealthFactor(address user) private view returns(uint256) {
        (uint256 totalCollateralUsd, uint256 totalBorrow) = _getAccountInformation(user);
        return _calculateHealthFactor(totalCollateralUsd, totalBorrow);
    }

    function _calculateHealthFactor(uint256 collateral, uint256 borrow) private pure returns(uint256){
        if (borrow == 0) return type(uint256).max;
        uint256 healthFactorAdj = (collateral * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (healthFactorAdj * PRECISION) / borrow;
    }







    /*//////////////////////////////////////////////////////////////
                                VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getDsc() external view returns(address) {
        return address(i_dsc);
    }

    function getCollateralTokens() external view returns(address[] memory){
        return s_collateralTokens;
    }

    function getPriceFeed(address token) external view returns(address){
        return s_priceFeeds[token];
    }

    function getUsdValue(address token, uint256 amount) external view returns(uint256){
        return _getUsdValue(token, amount);
    }

    function getTokenAmountFromUsd(address token, uint256 usdAmount) public view returns(uint256) {
        return _getTokenAmountFromUsd(token, usdAmount);
    }

    function getAdditionalFeedPrecision() external pure returns(uint256){
        return ADDITIONAL_FEED_PRECISION;
    }

    function getAccountInformation(address user) external view returns(uint256 totalCollateralUsd, uint256 totalBorrow) {
        return _getAccountInformation(user);
    }

    function getCollateralDeposited(address user, address token) external view returns(uint256) {
        return s_collateralDeposited[user][token];
    }

    function getDscMinted(address user) external view returns(uint256){
        return s_dscMinted[user];
    }

    function getHealthFactor(address user) external view returns(uint256){
        return _getHealthFactor(user); 
    }
}
