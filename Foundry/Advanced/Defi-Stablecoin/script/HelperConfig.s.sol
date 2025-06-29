// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {ERC20Mock} from "test/mocks/ERC20Mock.sol";

abstract contract CodeConstants {

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;
    int256 public constant BTC_USD_PRICE = 1000e8;

    address public constant SEPOLIA_WETH_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address public constant SEPOLIA_WBTC_FEED = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;

    address public constant SEPOLIA_WETH = 0xdd13E55209Fd76AfE204dBda4007C227904f0a81;
    address public constant SEPOLIA_WBTC = 0x4CB8445D3935d3649CF98Df403EC4C15860799CE;    

    uint256 public constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;
    uint256 public constant LIQUIDATION_PRECISION = 100;
    uint256 public constant LIQUIDATION_BONUS = 10;

    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant STARTING_USER_DEBT = 100 ether;

    address public constant WBTC_HOLDER = 0xd20e08766b2ebB24466eFaff47D523264550Ee06;
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
        // address dscToken; 
        address weth;
        address wbtc;  
        address wethFeed;
        address wbtcFeed;        
    }

    /*//////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 chainId => NetworkConfig) private s_networkConfigs;


    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() {
        s_networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
        s_networkConfigs[LOCAL_CHAIN_ID] = getOrCreateAnvilConfig();
    }

    function getConfig() public view returns(NetworkConfig memory){
        if(block.chainid == LOCAL_CHAIN_ID){
            return s_networkConfigs[LOCAL_CHAIN_ID];
        }
        else if(block.chainid == ETH_SEPOLIA_CHAIN_ID){
            return s_networkConfigs[ETH_SEPOLIA_CHAIN_ID];
        }
        else {
            revert HelperConfig__InvalidChainId();
        } 
    }

    /*//////////////////////////////////////////////////////////////
                                 SEPOLIA CONFIG
    //////////////////////////////////////////////////////////////*/

    function getSepoliaConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            weth: SEPOLIA_WETH,
            wbtc: SEPOLIA_WBTC,  
            wethFeed: SEPOLIA_WETH_FEED,
            wbtcFeed: SEPOLIA_WBTC_FEED  
        });
    }

    /*//////////////////////////////////////////////////////////////
                                 LOCAL CONFIG
    //////////////////////////////////////////////////////////////*/
    function getOrCreateAnvilConfig() public returns(NetworkConfig memory){
        if (s_networkConfigs[LOCAL_CHAIN_ID].weth != address(0)){
            return s_networkConfigs[LOCAL_CHAIN_ID];
        }
        vm.startBroadcast();
        ERC20Mock ethMock = new ERC20Mock("Ether", "ETH", msg.sender, 1000);
        ERC20Mock btcMock = new ERC20Mock("Bitcoin", "BTC", msg.sender, 1000);
        MockV3Aggregator ethFeed = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        MockV3Aggregator btcFeed = new MockV3Aggregator(DECIMALS, BTC_USD_PRICE);
        vm.stopBroadcast();
        return NetworkConfig({
            weth: address(ethMock),
            wbtc: address(btcMock),  
            wethFeed: address(ethFeed),
            wbtcFeed: address(btcFeed)  
        });
    }

}