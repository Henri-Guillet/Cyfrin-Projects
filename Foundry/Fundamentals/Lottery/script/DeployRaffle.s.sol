// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import { CreateSubscription, FundSubscription, AddConsumer } from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function deployContract() public returns (Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId == 0){
            //Create Subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator, config.account);
            //Fund it
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.subscriptionId, config.vrfCoordinator, config.link, config.account);

            helperConfig.setConfig(block.chainid, config);
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.subscriptionId,
            config.gasLane,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        //Add consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(config.subscriptionId, config.vrfCoordinator, address(raffle), config.account);

        return (raffle, helperConfig);
    }

    function run() external returns(Raffle, HelperConfig){
        return deployContract();
    }
}
