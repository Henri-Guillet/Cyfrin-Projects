// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {OracleLib} from "src/librairies/OracleLib.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";

contract OracleLibTest is Test, CodeConstants {

    //Types
    using OracleLib for MockV3Aggregator;

    //States
    MockV3Aggregator private wethFeed;
    
    function setUp() public {
        wethFeed = new MockV3Aggregator(8, ETH_USD_PRICE);
    }

    function test_OracleRevertsIfPriceFeedDoesntUpdate() public {
        vm.warp(block.timestamp + 4 hours);
        vm.expectRevert(abi.encode(
            OracleLib.OracleLib__StalePrice.selector
        ));
        wethFeed.staleCheckLatestRoundData();
    }

    function test_OracleRevertsIfBadAnswerInRound() public {
        uint80 _roundId = 0;
        int256 _answer = 0;
        uint256 _timestamp = 0;
        uint256 _startedAt = 0;
        wethFeed.updateRoundData(_roundId, _answer, _timestamp, _startedAt);

        vm.expectRevert(abi.encode(
            OracleLib.OracleLib__StalePrice.selector
        ));
        wethFeed.staleCheckLatestRoundData();
    }

    function test_OracleGivesPricesFeed() public view{
        (, int256 wethPrice, , , ) = wethFeed.staleCheckLatestRoundData();
        assertEq(wethPrice, ETH_USD_PRICE);
    }
}