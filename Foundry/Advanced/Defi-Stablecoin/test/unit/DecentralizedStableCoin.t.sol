// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoin public dsc;
    DSCEngine public dsce;
    HelperConfig.NetworkConfig private config;
    address user = makeAddr("user");
    
    function setUp() public {
        DeployDSC deployer = new DeployDSC();
        (dsce, dsc, config) = deployer.run();
    }

    /*//////////////////////////////////////////////////////////////
                                 Mint
    //////////////////////////////////////////////////////////////*/
    function test_RevertIfNotOwnerMint() public{
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            user
        ));
        dsc.mint(address(dsce), 10);        
    }

    function test_RevertIfMintToZeroAddress() public{
        vm.prank(address(dsce));
        vm.expectRevert(abi.encodeWithSelector(
            DecentralizedStableCoin.DecentralizedStableCoin__NotZeroAddress.selector
        ));
        dsc.mint(address(0), 10);        
    }

    function test_RevertIfAmountToMintNotMoreThanZero() public {
        vm.prank(address(dsce));
        vm.expectRevert(abi.encodeWithSelector(
            DecentralizedStableCoin.DecentralizedStableCoin__MoreThanZero.selector
        ));
        dsc.mint(user, 0);           
    }

    function test_OwnerCanMint() public {
        vm.prank(address(dsce));
        dsc.mint(user, 1000);
        uint256 balance = dsc.balanceOf(user);
        assert(balance == 1000);
    }


    /*//////////////////////////////////////////////////////////////
                                 Burn
    //////////////////////////////////////////////////////////////*/
    modifier mintToDsce(uint256 amount){
        vm.prank(address(dsce));
        dsc.mint(address(dsce), amount);
        _;
    }         

    function test_RevertIfNotOwnerBurn() public mintToDsce(1000) {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(
            Ownable.OwnableUnauthorizedAccount.selector,
            user
        ));
        dsc.burn(10);
    }

    function test_RevertIfAmountToBurnNotMoreThanZero() public mintToDsce(1000) {
        vm.prank(address(dsce));
        vm.expectRevert(abi.encodeWithSelector(
            DecentralizedStableCoin.DecentralizedStableCoin__MoreThanZero.selector
        ));
        dsc.burn(0);
    }

    function test_RevertIfAmountGreaterThanBalance() public mintToDsce(1000) {
        uint256 balance = dsc.balanceOf(address(dsce));
        vm.prank(address(dsce));
        vm.expectRevert(abi.encodeWithSelector(
            DecentralizedStableCoin.DecentralizedStableCoin__BurnAmountExceedsBalance.selector
        ));
        dsc.burn(balance + 1);
    }

    function test_OwnerCanBurn() public mintToDsce(1000) {
        uint256 amountToBurn = 50;
        uint256 startingBalance = dsc.balanceOf(address(dsce));
        vm.prank(address(dsce));
        dsc.burn(amountToBurn);
        uint256 expectedBalance = startingBalance - amountToBurn;
        uint256 endingBalance = dsc.balanceOf(address(dsce));
        assert(expectedBalance == endingBalance);       
    }

}