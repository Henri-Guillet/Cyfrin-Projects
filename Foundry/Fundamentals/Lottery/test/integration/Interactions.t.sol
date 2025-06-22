// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test } from "forge-std/Test.sol";
import "forge-std/console2.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import { CreateSubscription, FundSubscription, AddConsumer } from "script/Interactions.s.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Vm} from "forge-std/Vm.sol";

contract InteractionsTest is Test, CodeConstants {


    /* Events */
    event SubscriptionCreated(uint256 indexed subId, address owner);

    function setUp() public {

    }

    function test_createSubscription() public {
        //Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        bytes32 SUB_SIG = keccak256("SubscriptionCreated(uint256,address)");
        uint256 subId;
        //Act
        vm.recordLogs();
        HelperConfig.NetworkConfig memory config = createSubscription.run();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++){
            if(entries[i].topics.length > 1 && entries[i].topics[0] == SUB_SIG){
                subId = uint256(entries[i].topics[1]);
            }
        }
        //Assert
        assert(config.subscriptionId == uint256(subId));
    }

    
    function test_fundSubscription() public {
        //Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        HelperConfig.NetworkConfig memory config = createSubscription.run();
        FundSubscription fundSubscription = new FundSubscription();
        //Act & Assert
        fundSubscription.fundSubscription(config.subscriptionId, config.vrfCoordinator, config.link, config.account);
        if (block.chainid == LOCAL_CHAIN_ID){
            uint96 totalBalance = VRFCoordinatorV2_5Mock(config.vrfCoordinator).s_totalBalance();
            console2.log("total balance", totalBalance);
            assert( uint256(totalBalance) == 3100 ether);
        }
    }
}