// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import { FundMe } from "../src/FundMe.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 amountToFund = 0.1 ether;

    function fundFundMe(address mostRecentDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentDeployed)).fund{value: amountToFund}();
        vm.stopBroadcast();        
    }

    function run() public {
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        fundFundMe(mostRecentDeployed);
    }
}