// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { DeployRaffle } from "../../script/DeployRaffle.s.sol";
import { Raffle } from "../../src/Raffle.sol";
import { HelperConfig, CodeConstants } from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;
    address PLAYER = makeAddr("PLAYER");
    uint256 STARTING_PLAYER_BALANCE = 10 ether;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    uint256 subscriptionId;
    bytes32 gasLane;
    uint32 callbackGasLimit;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

            

    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        subscriptionId = config.subscriptionId;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
    }

    function test_RaffleInitializesInOpenState() public view {
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(raffleState == Raffle.RaffleState.OPEN);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/

    function test_CheckMinimumEntrance() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function test_PlayerAddedToRaffle() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        assertEq(raffle.getPlayer(0), PLAYER);
    }

    function test_EnteringRaffleEmitsEvent() public {
        //Arrange
        vm.prank(PLAYER);
        //Act & Assert
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function test_NotPossibleToEnterWhenNotOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act & Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECKUPKEEP
    //////////////////////////////////////////////////////////////*/

    function test_CheckUpKeepReturnsFalseIfNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upKeepNeeded);
    }

    function test_CheckUpKeepReturnsFalseIfNotOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upKeepNeeded);        
    }

    function test_CheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number + 1);        

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upKeepNeeded);  
    }

    function test_CheckUpKeepReturnsTrueWhenParametersAreOk() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");   

        //Assert
        assert(upKeepNeeded);      
    }

    /*//////////////////////////////////////////////////////////////
                              PERFORMKEEP
    //////////////////////////////////////////////////////////////*/
    function test_CanRunIfUpKeepTrue() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act & Assert
        raffle.performUpkeep("");
    }

    function test_RevertsIfUpKeepFalse() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        uint256 balance = address(raffle).balance;
        uint256 nbPlayers = 1;
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        //Act & Assert
        vm.expectRevert(abi.encodeWithSelector(
            Raffle.Raffle__upKeepNotNeeded.selector,
            balance,
            nbPlayers,
            raffleState
        ));
        raffle.performUpkeep("");
    }

    function test_PerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        //Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
    }

    /*//////////////////////////////////////////////////////////////
                           FULFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;        
    }

    modifier skipFork() {
        if(block.chainid != LOCAL_CHAIN_ID){
            return;
        }
        _;
    }

    function test_FulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 requestId) public raffleEntered skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(raffle));
    }

    function test_FulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered skipFork {
        //Arrange
        address expectedWinner = address(1);
        uint160 nbAddPlayers = 3;
        for(uint160 i = 1; i < nbAddPlayers + 1; i++){
            address playerAddress = address(i);
            hoax(playerAddress, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingBalance = expectedWinner.balance;
        uint256 startingTimestamp = raffle.getLastTimestamp();

        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        //Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 prize = entranceFee * (nbAddPlayers + 1);
        uint256 endingTimestamp = raffle.getLastTimestamp();

        assert(expectedWinner == recentWinner);
        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(winnerBalance == startingBalance + prize);
        assert(endingTimestamp > startingTimestamp);

    }
}