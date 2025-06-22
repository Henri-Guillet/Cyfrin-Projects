// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import "forge-std/console2.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import { LinkToken } from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns(HelperConfig.NetworkConfig memory) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        (config.subscriptionId, ) = createSubscription(config.vrfCoordinator, config.account);
        return config;
    }

    function createSubscription(address vrfCoordinator, address account) public returns(uint256, address) {
        console2.log("Creating a sub Id on chain Id :", block.chainid);
        vm.startBroadcast(account);
        console2.log("account", account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console2.log("Your sub Id is :", subId);
        console2.log("Please update the sub Id in your HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }

    function run() public returns(HelperConfig.NetworkConfig memory) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; //LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        fundSubscription(config.subscriptionId, config.vrfCoordinator, config.link, config.account);
    }

    function fundSubscription(uint256 subId, address vrfCoordinator, address link, address account) public {
        console2.log("Funding subscriptionId: ", subId);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainID: ", block.chainid);
        if (block.chainid == LOCAL_CHAIN_ID){
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT * 1000);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        } 
    }

    function run() public{
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        addConsumer(config.subscriptionId, config.vrfCoordinator, mostRecentlyDeployed, config.account);
    }

    function addConsumer(uint256 subId, address vrfCoordinator, address contractToAddToVrf, address account) public {
        console2.log("Adding consumer contract: ", contractToAddToVrf);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainID: ", block.chainid);
        console2.log("account", account);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }
    
    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}