// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

// Ajoutez ceci en haut du fichier
interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function balanceOf(address) external view returns (uint);
}

contract StopOnRevertHandler is Test, CodeConstants {
    DecentralizedStableCoin public dsc;
    DSCEngine public dsce;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public weth;
    address public wbtc;

    uint256 public constant MAX_DEPOSIT = type(uint96).max;

    EnumerableSet.AddressSet private depositors;

    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dsc = _dsc;
        dsce = _dscEngine;

        weth = dsce.getCollateralTokens()[0];
        wbtc = dsce.getCollateralTokens()[1];
    }
    /*//////////////////////////////////////////////////////////////
                                 Helpers
    //////////////////////////////////////////////////////////////*/
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(address) {
        if(collateralSeed % 2 == 0) return weth;
        else return wbtc;
    }

    function _getDepositorsFromSeed(uint256 depositorSeed) private view returns(address) {
        if(depositors.length() == 0) return address(0);
        uint index = depositorSeed % depositors.length();
        return depositors.at(index);
    }

    /*//////////////////////////////////////////////////////////////
                                 Functions
    //////////////////////////////////////////////////////////////*/
    function depositCollateral(uint256 amountCollateral, uint256 collateralSeed) public {
        address collateralToken = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT);

        
        vm.startPrank(msg.sender);
        ERC20Mock(collateralToken).mint(msg.sender, amountCollateral);
        ERC20Mock(collateralToken).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(amountCollateral, collateralToken);
        vm.stopPrank();

        depositors.add(msg.sender);
    }

    function redeemCollateral(uint256 amountToRedeem, uint256 collateralSeed, uint256 depositorSeed) public {
        //get an address that has alreaday deposited
        address user = _getDepositorsFromSeed(depositorSeed);
        if (user == address(0)) return;
        //get the max collateral that can be redeemed considering collateral and dsc already minted
        address collateralToken = _getCollateralFromSeed(collateralSeed);
        (uint256 collateralValue, uint256 debtValue) = dsce.getAccountInformation(user);
        int256 maxRedeem = int256(collateralValue) - (int256(debtValue) * int256(LIQUIDATION_PRECISION)) / int256(LIQUIDATION_THRESHOLD);
        if (maxRedeem <= 0) return;
        uint256 maxRedeemToken = dsce.getTokenAmountFromUsd(collateralToken, uint256(maxRedeem));
        uint256 currentAmountOfTokenForCollateral = dsce.getCollateralDeposited(user, collateralToken);
        if (maxRedeemToken == 0) return;
        if (currentAmountOfTokenForCollateral < maxRedeemToken) return;
        amountToRedeem = bound(amountToRedeem, 1, maxRedeemToken);

        vm.prank(user);
        dsce.redeemCollateral(amountToRedeem, collateralToken);
    }

    function mintDsc(uint256 amount, uint256 depositorSeed) public {
        //get an address that has alreaday deposited
        address user = _getDepositorsFromSeed(depositorSeed);
        if (user == address(0)) return;
        //get the max dsc amount that can be minted considering collateral and dsc already minted
        (uint256 collateralValue, uint256 debtValue) = dsce.getAccountInformation(user);
        int256 maxMint = (int256(collateralValue) * int256(LIQUIDATION_THRESHOLD)) / int256(LIQUIDATION_PRECISION) - int256(debtValue);
        if (maxMint <= 0) return;
        amount = bound(amount, 1, uint256(maxMint));

        vm.prank(user);
        dsce.mintDsc(amount);
    }

}