// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";
import {StopOnRevertHandler} from "./stopOnRevertHandler.t.sol";

contract StopOnRevertInvariants is Test, CodeConstants {
    HelperConfig.NetworkConfig public config;
    DecentralizedStableCoin public dsc;
    DSCEngine public dsce;

    address public weth;
    address public wbtc;
    address public wethFeed;
    address public wbtcFeed;

    function setUp() public {
        if (block.chainid != LOCAL_CHAIN_ID) {
            vm.skip(true);
            return;     
        }
        DeployDSC deployer = new DeployDSC();
        (dsce, dsc, config) = deployer.run();
        weth = config.weth;
        wbtc = config.wbtc;
        wethFeed = config.wethFeed;
        wbtcFeed = config.wbtcFeed;

        StopOnRevertHandler handler = new StopOnRevertHandler(dsce, dsc);
        targetContract(address(handler));
    }

    /*//////////////////////////////////////////////////////////////
                                 Functions
    //////////////////////////////////////////////////////////////*/
    function invariant_ProtocolMustHaveMoreValueThanTotalDebt() public view{
        uint256 totalDebt = dsc.totalSupply();
        uint256 totalWeth = ERC20Mock(weth).balanceOf(address(dsce));
        uint256 totalWbtc = ERC20Mock(wbtc).balanceOf(address(dsce));
        uint256 totalWethValue = dsce.getUsdValue(weth, totalWeth);
        uint256 totalWbtcValue = dsce.getUsdValue(weth, totalWbtc);

        console2.log("totalWethValue", totalWethValue);
        console2.log("totalWbtcValue", totalWbtcValue);
        console2.log("totalDebt", totalDebt);

        assert(totalWethValue + totalWbtcValue >= totalDebt);
    }

    function invariant_GettersCantRevert() public view{
        dsce.getDsc();
        dsce.getCollateralTokens();
        dsce.getPriceFeed(weth);
        dsce.getUsdValue(weth, 1 ether);
        dsce.getTokenAmountFromUsd(weth, 1 ether);
        dsce.getAdditionalFeedPrecision();
        dsce.getAccountInformation(address(1));
        dsce.getCollateralDeposited(address(1), weth);
        dsce.getDscMinted(address(1));
        dsce.getHealthFactor(address(1));
    }
}