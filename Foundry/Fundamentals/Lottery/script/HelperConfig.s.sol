// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import { VRFCoordinatorV2_5Mock } from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { LinkToken } from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants {

    /* VRF Mock Values */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS8PRIC_LINK = 1e9;
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15;

    address public constant ANVIL_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /*//////////////////////////////////////////////////////////////
                               CHAIN IDS
    //////////////////////////////////////////////////////////////*/
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

}


contract HelperConfig is Script, CodeConstants {

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        uint256 subscriptionId;
        bytes32 gasLane;
        uint32 callbackGasLimit;
        address link;
        address account;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public s_networkConfigs;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(){
        s_networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        if(s_networkConfigs[chainId].vrfCoordinator != address(0)){
            return s_networkConfigs[chainId];
        } else if(chainId == LOCAL_CHAIN_ID){
            return getOrCreateAnvilConfig();
        } else{
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function setConfig(
        uint256 chainId,
        NetworkConfig memory networkConfig
    ) public {
        s_networkConfigs[chainId] = networkConfig;
    }

    /*//////////////////////////////////////////////////////////////
                                CONFIGS
    //////////////////////////////////////////////////////////////*/

    function getSepoliaConfig() public pure returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, //seconds
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            subscriptionId: 101381162063178166918243698037980105803924568299977771114378836498459896197685,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit:500000,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            account: 0xd20e08766b2ebB24466eFaff47D523264550Ee06
        });
    }


    /*//////////////////////////////////////////////////////////////
                              LOCAL CONFIG
    //////////////////////////////////////////////////////////////*/
    function getOrCreateAnvilConfig() public returns(NetworkConfig memory){
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }

        vm.startBroadcast(ANVIL_ADDRESS);
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS8PRIC_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken link = new LinkToken();
        uint256 subscriptionId = vrfCoordinator.createSubscription();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, 100 ether);
        vm.stopBroadcast();
        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30, //seconds
            vrfCoordinator: address(vrfCoordinator),
            subscriptionId: subscriptionId,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit:500000, 
            link: address(link),
            account: ANVIL_ADDRESS             
        });
        vm.deal(localNetworkConfig.account, 100 ether); 
        return localNetworkConfig; 
    }

}