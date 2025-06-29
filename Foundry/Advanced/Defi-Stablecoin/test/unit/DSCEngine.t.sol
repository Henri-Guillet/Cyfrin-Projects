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
import {ERC20MockFailedTransfer} from "test/mocks/ERC20MockFailedTransfer.sol";
import {ERC20MockFailedTransferFrom} from "test/mocks/ERC20MockFailedTransferFrom.sol";
import {ERC20MockMintDscFailed} from "test/mocks/ERC20MockMintDscFailed.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract DSCEngineTest is Test, CodeConstants {
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed from,address indexed to, address tokenCollateralAddress, uint256 amount);

    HelperConfig.NetworkConfig public config;
    DecentralizedStableCoin public dsc;
    DSCEngine public dsce;

    address public user = makeAddr("user");

    address public weth;
    address public wbtc;
    address public wethFeed;
    address public wbtcFeed;

    function setUp() public {
        DeployDSC deployer = new DeployDSC();
        (dsce, dsc, config) = deployer.run();
        
        weth = config.weth;
        wbtc = config.wbtc;
        wethFeed = config.wethFeed;
        wbtcFeed = config.wbtcFeed;
        
        vm.deal(user, STARTING_USER_BALANCE);
        if(block.chainid == LOCAL_CHAIN_ID){
            ERC20Mock(weth).mint(user, STARTING_USER_BALANCE);
            ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
        }
        else if (block.chainid == ETH_SEPOLIA_CHAIN_ID){
            vm.prank(WBTC_HOLDER);
            ERC20Mock(wbtc).transfer(user, 100 ether);
            vm.prank(user);
            (bool success , ) = payable(weth).call{value: STARTING_USER_BALANCE}(abi.encodeWithSignature("deposit()"));
            require(success, "WETH deposit failed");
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 Helper functions
    //////////////////////////////////////////////////////////////*/
    function _compareArrays(address[] memory array1, address[] memory array2) private pure returns(bool){
        if(array1.length != array2.length){
            return false;
        }
        for (uint256 i = 0; i < array1.length; i++){
            if(array1[i] != array2[i]){
                return false;
            }
        }
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                                 Modifiers
    //////////////////////////////////////////////////////////////*/
    modifier skipFork() {
        if(block.chainid != LOCAL_CHAIN_ID){
            return;
        }
        _;
    }

    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), STARTING_USER_BALANCE);
        dsce.depositCollateral(STARTING_USER_BALANCE, weth);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), STARTING_USER_BALANCE);
        dsce.depositCollateralAndMintDsc(STARTING_USER_BALANCE, weth, STARTING_USER_DEBT);
        vm.stopPrank();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 Constructor
    //////////////////////////////////////////////////////////////*/
    address[] public tokens;
    address[] public priceFeeds;

    function test_ConstructorRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokens = [weth, wbtc];
        priceFeeds = [wethFeed];
        vm.expectRevert(abi.encodeWithSelector(
            DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector
        ));
        new DSCEngine(address(dsc), tokens, priceFeeds);
    }

    function test_ConstructorDscAddress() public view {
        assert(address(dsc) == dsce.getDsc());
    }

    function test_ConstructorCollateralTokens() public view {
        address[] memory collateralTokens = new address[](2);
        collateralTokens[0] = weth;
        collateralTokens[1] = wbtc;
        address[] memory getCollateralTokens = dsce.getCollateralTokens();
        assert(_compareArrays(collateralTokens, getCollateralTokens)); 
    }

    function test_ConstructorPriceFeeds() public view {
        assert(wethFeed == dsce.getPriceFeed(weth));
        assert(wbtcFeed == dsce.getPriceFeed(wbtc));
    }

    /*//////////////////////////////////////////////////////////////
                                 Price Test
    //////////////////////////////////////////////////////////////*/
    function test_GetUsdValue() public view {
        uint256 wethValue = dsce.getUsdValue(weth, 1 ether);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, 1 ether);
        (,int256 wethUsdPrice,,,) = MockV3Aggregator(wethFeed).latestRoundData();
        (,int256 wbtcUsdPrice,,,) = MockV3Aggregator(wbtcFeed).latestRoundData();
        uint256 wethExpectedPrice = uint256(wethUsdPrice) * dsce.getAdditionalFeedPrecision();
        uint256 wbtcExpectedPrice = uint256(wbtcUsdPrice) * dsce.getAdditionalFeedPrecision();

        assertEq(wethValue, wethExpectedPrice);
        assertEq(wbtcValue, wbtcExpectedPrice);
    }

    function test_GetTokenAmountFromUsd() public view {
        uint256 usdAmount = 1 ether;
        uint256 wethAmount = dsce.getTokenAmountFromUsd(weth, usdAmount);
        uint256 wbtcAmount = dsce.getTokenAmountFromUsd(wbtc, usdAmount);
        (,int256 wethUsdPrice,,,) = MockV3Aggregator(wethFeed).latestRoundData();
        (,int256 wbtcUsdPrice,,,) = MockV3Aggregator(wbtcFeed).latestRoundData();
        uint256 expectedWethAmount = (usdAmount * PRECISION) / (uint256(wethUsdPrice) * ADDITIONAL_FEED_PRECISION);
        uint256 expectedWbtcAmount = (usdAmount * PRECISION) / (uint256(wbtcUsdPrice) * ADDITIONAL_FEED_PRECISION);
        assertEq(wethAmount, expectedWethAmount);
        assertEq(wbtcAmount, expectedWbtcAmount);
    }

    /*//////////////////////////////////////////////////////////////
                                 Deposit collateral
    //////////////////////////////////////////////////////////////*/  
    function test_DepositRevertIfAmountNotMoreThanZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(user, STARTING_USER_BALANCE);
        vm.expectRevert(abi.encodeWithSelector(
            DSCEngine.DSCEngine__MoreThanZero.selector
        ));
        dsce.depositCollateral(0, weth);
        vm.stopPrank();
    }

    function test_DepositRevertIfTokenNotAllowed() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(
            DSCEngine.DSCEngine__TokenNotAllowed.selector,
            address(1)
        ));
        dsce.depositCollateral(1 ether, address(1));        
    }

    function test_DepositRevertIfBalanceTooLow() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(user, STARTING_USER_BALANCE + 1);
        vm.expectRevert(abi.encodeWithSelector(
            DSCEngine.DSCEngine__BalanceTooLow.selector
        ));
        dsce.depositCollateral(STARTING_USER_BALANCE + 1, weth);
        vm.stopPrank();        
    }

    function test_EmitEventWhenDepositingCollateral() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), STARTING_USER_BALANCE);
        vm.expectEmit(true, true, true, false, address(dsce));
        emit CollateralDeposited(user, weth, STARTING_USER_BALANCE);
        dsce.depositCollateral(STARTING_USER_BALANCE, weth);
        vm.stopPrank();
    }

    function test_DepositCollateralRevertsIfFailedTransfer() public{
        ERC20MockFailedTransferFrom erc20FailedTransfer = new ERC20MockFailedTransferFrom(user, 10 ether);
        tokens = [address(erc20FailedTransfer)];
        priceFeeds = [wethFeed];

        DSCEngine dsceMock = new DSCEngine(address(dsc), tokens, priceFeeds);
        vm.prank(user);
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__TransferFailed.selector
        ));
        dsceMock.depositCollateral(1 ether, address(erc20FailedTransfer));
    }

    function test_CanDepositCollateralAndGetAccountInformation() public depositedCollateral {
        (uint256 collateralUsd, uint256 dscMinted) = dsce.getAccountInformation(user);
        uint256 collateralInToken = dsce.getTokenAmountFromUsd(weth, collateralUsd);
        uint256 collateralToken = dsce.getCollateralDeposited(user, weth);
        assert(collateralInToken == STARTING_USER_BALANCE);
        assert(collateralToken == STARTING_USER_BALANCE);
        assert( dscMinted == 0);
    }

    /*//////////////////////////////////////////////////////////////
                                 Mint Dsc
    //////////////////////////////////////////////////////////////*/
    function test_MintDscRevertsIfBreaksHealthFactor() public depositedCollateral {
        //Arrange
        (uint256 totalCollateralUsd, ) = dsce.getAccountInformation(user);
        uint256 mintLimit = (totalCollateralUsd * LIQUIDATION_THRESHOLD * PRECISION) /  (LIQUIDATION_PRECISION * MIN_HEALTH_FACTOR);
        uint256 amountToMint = mintLimit + 1;

        //Act & Assert
        vm.startPrank(user);
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__HealthFactorBroken.selector
        ));
        dsce.mintDsc(amountToMint);
        vm.stopPrank();   
    }

    function test_MintDscRevertsIfTransferFails() public {
        //Arrange
        ERC20MockMintDscFailed dscMock = new ERC20MockMintDscFailed();
        tokens = [weth];
        priceFeeds = [wethFeed];
        DSCEngine dsceMock = new DSCEngine(address(dscMock), tokens, priceFeeds);
        dscMock.transferOwnership(address(dsceMock));
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsceMock), 1 ether);
        dsceMock.depositCollateral(1 ether, weth);
        vm.stopPrank();

        //Act & Assert
        vm.prank(user);
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__MintFailed.selector
        ));
        dsceMock.mintDsc(0.1 ether);
    }

    function test_CanMintDsc() public depositedCollateral {
        //Arrange
        (uint256 totalCollateralUsd, ) = dsce.getAccountInformation(user);
        uint256 mintLimit = (totalCollateralUsd * LIQUIDATION_THRESHOLD * PRECISION) /  (LIQUIDATION_PRECISION * MIN_HEALTH_FACTOR);
        uint256 amountToMint = mintLimit;

        //Act
        vm.prank(user);
        dsce.mintDsc(amountToMint);

        //Assert
        uint256 dscMinted = dsce.getDscMinted(user);
        assert(dscMinted == amountToMint);
    }

    /*//////////////////////////////////////////////////////////////
                                 Deposit collateral and mint Dsc
    //////////////////////////////////////////////////////////////*/
    function test_CanDepositCollateralAndMintDsc() public {
        //Arrange
        uint256 amountToDeposit = 1 ether;
        uint256 depositUsdValue = dsce.getUsdValue(weth, amountToDeposit);
        uint256 mintLimit = (depositUsdValue * LIQUIDATION_THRESHOLD * PRECISION) /  (LIQUIDATION_PRECISION * MIN_HEALTH_FACTOR);
        uint256 amountToMint = mintLimit;

        //Act
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountToDeposit);
        dsce.depositCollateralAndMintDsc(amountToDeposit, weth, amountToMint);
        vm.stopPrank();

        //Assert
        uint256 collateralToken = dsce.getCollateralDeposited(user, weth);
        uint256 dscMinted = dsce.getDscMinted(user);
        assert(collateralToken == amountToDeposit);
        assert(dscMinted == amountToMint);
    }

    function test_DepositCollateralAndMintDscRevertIfTooMuchDscMinted() public {
        //Arrange
        uint256 amountToDeposit = 1 ether;
        uint256 depositUsdValue = dsce.getUsdValue(weth, amountToDeposit);
        uint256 mintLimit = (depositUsdValue * LIQUIDATION_THRESHOLD * PRECISION) /  (LIQUIDATION_PRECISION * MIN_HEALTH_FACTOR);
        uint256 amountToMint = mintLimit + 1;

        //Act & Assert
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountToDeposit);
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__HealthFactorBroken.selector
        ));
        dsce.depositCollateralAndMintDsc(amountToDeposit, weth, amountToMint);
        vm.stopPrank();        
    }

    /*//////////////////////////////////////////////////////////////
                                 Redeem Collateral
    //////////////////////////////////////////////////////////////*/
    function test_CanRedeemCollateral() public depositedCollateralAndMintedDsc{
        //Arrange
        uint256 amountMinted = dsce.getDscMinted(user);
        uint256 startingCollateral = dsce.getCollateralDeposited(user, weth);
        uint256 minCollateralValue = (amountMinted * LIQUIDATION_PRECISION * MIN_HEALTH_FACTOR) / (LIQUIDATION_THRESHOLD * PRECISION);
        uint256 minCollateral = dsce.getTokenAmountFromUsd(weth, minCollateralValue);
        uint256 collateralToRedeem = startingCollateral - minCollateral - 1;

        //Act
        vm.prank(user);
        vm.expectEmit(true, true, false, false, address(dsce));
        emit CollateralRedeemed(user, user, weth, collateralToRedeem);
        dsce.redeemCollateral(collateralToRedeem, weth);

        //Assert
        uint256 endingCollateral = dsce.getCollateralDeposited(user, weth);
        uint256 expectedCollateral = startingCollateral - collateralToRedeem;
        assertEq(endingCollateral, expectedCollateral);
    }

    function test_RedeemCollateralRevertsIfNotEnoughCollateral() public depositedCollateralAndMintedDsc {
        //Arrange
        uint256 amountMinted = dsce.getDscMinted(user);
        uint256 startingCollateral = dsce.getCollateralDeposited(user, weth);
        uint256 minCollateralValue = (amountMinted * LIQUIDATION_PRECISION) / LIQUIDATION_THRESHOLD;
        uint256 minCollateral = dsce.getTokenAmountFromUsd(weth, minCollateralValue);
        uint256 collateralToRedeem = startingCollateral - minCollateral + 1;

        //Act && assert
        vm.prank(user);
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__HealthFactorBroken.selector
        ));
        dsce.redeemCollateral(collateralToRedeem, weth);
    }

    function test_RedeemCollateralRevertsIfNotMoreThanZero() public depositedCollateralAndMintedDsc {
        vm.prank(user);
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__MoreThanZero.selector
        ));
        dsce.redeemCollateral(0, weth);
    }

    function test_RedeemCollateralRevertsIfNotAllowedToken() public depositedCollateralAndMintedDsc {
        vm.prank(user);
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__TokenNotAllowed.selector
        ));
        dsce.redeemCollateral(1, address(1));
    }

    function test_RedeemCollateralRevertsIfFailedTransfer() public{
        //Arrange
        ERC20MockFailedTransfer erc20FailedTransfer = new ERC20MockFailedTransfer(user, 10 ether);
        tokens = [address(erc20FailedTransfer)];
        priceFeeds = [wethFeed];
        DSCEngine dsceMock = new DSCEngine(address(dsc), tokens, priceFeeds);
        vm.startPrank(user);
        ERC20MockFailedTransfer(erc20FailedTransfer).approve(address(dsceMock), 1 ether);
        dsceMock.depositCollateral(1 ether, address(erc20FailedTransfer));

        //Act && Assert
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__TransferFailed.selector
        ));
        dsceMock.redeemCollateral(0.5 ether, address(erc20FailedTransfer));

    }

   /*//////////////////////////////////////////////////////////////
                                 Burn Dsc
    //////////////////////////////////////////////////////////////*/
    function test_BurnDscRevertsIfNotMoreThanZero() public depositedCollateralAndMintedDsc{
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__MoreThanZero.selector
        ));
        vm.prank(user);
        dsce.burnDsc(0);
    }

    function test_CantBurnMoreDscThanUserHas() public {
        vm.expectRevert();
        vm.prank(user);
        dsce.burnDsc(1);
    }

    function test_CanBurnDsc() public depositedCollateralAndMintedDsc {
        //Arrange
        uint256 amountMinted = dsce.getDscMinted(user);

        //Act
        vm.startPrank(user);
        dsc.approve(address(dsce), amountMinted);
        dsce.burnDsc(amountMinted);
        vm.stopPrank();

        //Assert
        uint256 dscBalance = dsc.balanceOf(user);
        assertEq(dscBalance, 0);
    }
    
    /*//////////////////////////////////////////////////////////////
                                 Redeem Collateral for Dsc
    //////////////////////////////////////////////////////////////*/
    function test_CanRedeemCollateralForDsc() public depositedCollateralAndMintedDsc {
        //Arrange
        uint256 amountMinted = dsce.getDscMinted(user);
        uint256 dscToBurn = amountMinted / 2;
        uint256 startingCollateral = dsce.getCollateralDeposited(user, weth);
        uint256 minCollateralValue = ((amountMinted - dscToBurn) * LIQUIDATION_PRECISION) / LIQUIDATION_THRESHOLD;
        uint256 minCollateral = dsce.getTokenAmountFromUsd(weth, minCollateralValue);
        uint256 collateralToRedeem = startingCollateral - minCollateral - 1;

        //Act
        vm.startPrank(user);
        dsc.approve(address(dsce), dscToBurn);
        dsce.redeemCollateralForDsc(collateralToRedeem, weth, dscToBurn);
        vm.stopPrank();

        //Assert
        uint256 endingCollateral = dsce.getCollateralDeposited(user, weth);
        uint256 endingDscMinted = dsce.getDscMinted(user);
        assertEq(endingCollateral, startingCollateral - collateralToRedeem);
        assertEq(endingDscMinted, amountMinted - dscToBurn);
    }

    /*//////////////////////////////////////////////////////////////
                                 Health Factor
    //////////////////////////////////////////////////////////////*/
    function test_HealthFactor() public depositedCollateralAndMintedDsc{
        //Arrange
        (uint256 collateralValue, uint256 borrow) = dsce.getAccountInformation(user);
        uint256 expectedHealthFactor = (collateralValue * LIQUIDATION_THRESHOLD * PRECISION) / (borrow * LIQUIDATION_PRECISION);
        //Act
        uint256 healthFactor = dsce.getHealthFactor(user);

        //Assert
        assertEq(healthFactor, expectedHealthFactor);
    }

    function test_HealthFactorCanGoBelowOne() public depositedCollateralAndMintedDsc skipFork{
        //Act
        // HF = collateral * price * liquidationratio / borrow = 0.9
        // price = 0.9 * borrow / (collateral * liquidationratio) = 0.9 * 100eth / (10eth * 0.5) = 0.9 * 10 * 2 = 18
        MockV3Aggregator(wethFeed).updateAnswer(18e8);

        //Assert
        uint256 healthFactor = dsce.getHealthFactor(user);
        assertEq(healthFactor, 0.9 ether);
    }


    /*//////////////////////////////////////////////////////////////
                                 Liquidation
    //////////////////////////////////////////////////////////////*/
    function test_LiquidateRevertsIfHealthFactorAboveOne() public depositedCollateralAndMintedDsc{
        vm.expectRevert(abi.encode(
            DSCEngine.DSCEngine__HealthFactorIsOk.selector
        ));
        address liquidator = makeAddr("liquidator");
        vm.prank(liquidator);
        dsce.liquidate(weth, user, 1 ether);
    }

    function test_CanLiquidateIfHealthFactorBelowOne() public depositedCollateralAndMintedDsc skipFork{
        //Arrange
        MockV3Aggregator(wethFeed).updateAnswer(18e8);
        address liquidator = makeAddr("liquidator");
        (, uint256 userStartingDebt) = dsce.getAccountInformation(user);
        uint256 userStartingCollateral = dsce.getCollateralDeposited(user, weth);
        //CollateralUsd = 10 * 18
        //Liquidation threshold = 0.5
        //Liquidation bonus = 10%
        //(Borrow - x) < (CollateralUsd - x(1+LiquidationBonus)) * LiquidationThreshold
        // x > (B - LiquidationThreshold * CollateralUsd) / (1 - (1 + LiquidationBonus) * LiquidationThreshold) = 22.2222...
        // Liquidator should pay back at least 22.22222... dsc to get Health factor above 1
        uint256 debtToCover = 23 ether;
        vm.prank(address(dsce));
        dsc.mint(liquidator, debtToCover);

        //Act
        vm.startPrank(liquidator);
        dsc.approve(address(dsce), debtToCover);
        dsce.liquidate(weth, user, debtToCover);
        vm.stopPrank();

        //Assert
        // expected collateral withdrawn (in usd) = debt repaid (in usd) + 10% = 23 * 1.1 = 25.3
        uint256 expectedCollateralWithdrawn = dsce.getTokenAmountFromUsd(weth, debtToCover);
        expectedCollateralWithdrawn = expectedCollateralWithdrawn * (LIQUIDATION_PRECISION + LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        (, uint256 endingUserDebt) = dsce.getAccountInformation(user);
        uint256 endingUserCollateral = dsce.getCollateralDeposited(user, weth);
        assertEq(userStartingCollateral - expectedCollateralWithdrawn, endingUserCollateral);
        assertEq(userStartingDebt - debtToCover, endingUserDebt);
    }    
}