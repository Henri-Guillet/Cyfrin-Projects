// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {BoxV1} from "src/BoxV1.sol";
import {ERC1967Proxy} from  "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployProxy is Script {
    function deployProxy() public returns(address){
        vm.startBroadcast();
        BoxV1 boxV1 = new BoxV1();
        ERC1967Proxy proxy = new ERC1967Proxy(address(boxV1), "");
        BoxV1(address(proxy)).initialize();
        vm.stopBroadcast();
        return address(proxy);
    }

    function run() public returns(address){
        return deployProxy();
    }
}