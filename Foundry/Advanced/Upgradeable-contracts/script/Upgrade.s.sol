// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "src/BoxV1.sol";
import {BoxV2} from "src/BoxV2.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract Upgrade is Script {
    function upgrade(address proxy, address box) public {
        vm.startBroadcast();
        BoxV1(proxy).upgradeToAndCall(box, "");
        vm.stopBroadcast();
    }

    function run() public {
        address proxy = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", block.chainid);
        vm.startBroadcast();
        BoxV2 boxV2 = new BoxV2();
        vm.stopBroadcast();
        upgrade(proxy, address(boxV2));
    }
}