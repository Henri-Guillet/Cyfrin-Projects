// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/*
 * @title OracleLib
 * @author Henri Guillet
 * @notice This library is used to check the Chainlink Oracle for stale data.
 * If a price is stale, functions will revert, and render the DSCEngine unusable - this is by design.
 * We want the DSCEngine to freeze if prices become stale.
 *
 * So if the Chainlink network explodes and you have a lot of money locked in the protocol... too bad.
 */
library OracleLib {
    error OracleLib__StalePrice();

    uint256 constant private HEARTBEAT = 3 hours;

    function staleCheckLatestRoundData (AggregatorV3Interface aggregatorV3Interface) 
        public 
        view 
        returns(uint80, int256, uint256, uint256, uint80) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = aggregatorV3Interface.latestRoundData();

        if (updatedAt == 0 || answeredInRound < roundId){
            revert OracleLib__StalePrice();
        }

        if(block.timestamp - updatedAt > HEARTBEAT){
            revert OracleLib__StalePrice();
        }

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

}