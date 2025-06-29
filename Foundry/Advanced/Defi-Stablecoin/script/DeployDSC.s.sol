// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {DSCEngine, DecentralizedStableCoin} from "src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokens;
    address[] public priceFeeds;

    function deployContract() public returns(
        DSCEngine, 
        DecentralizedStableCoin, 
        HelperConfig.NetworkConfig memory
    )
    {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        
        tokens = [config.weth, config.wbtc];
        priceFeeds = [config.wethFeed, config.wbtcFeed];

        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(
            address(dsc),
            tokens,
            priceFeeds
        );
        dsc.transferOwnership(address(dscEngine));
        vm.stopBroadcast();
        return (dscEngine, dsc, config);
    }

    function run() public returns(DSCEngine, DecentralizedStableCoin, HelperConfig.NetworkConfig memory){
        return deployContract();
    }
}