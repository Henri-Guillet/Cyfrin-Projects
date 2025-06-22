// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import { FundMe } from "../src/FundMe.sol";
import { PriceConverter } from "../src/PriceConverter.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() public returns(FundMe){
        HelperConfig helperConfig = new HelperConfig();
        address priceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;

        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}