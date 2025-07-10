// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {DeployProxy} from "script/Deployer.s.sol";
import {Upgrade} from "script/Upgrade.s.sol";
import {BoxV1} from "src/BoxV1.sol";
import {BoxV2} from "src/BoxV2.sol";

import {Test} from "forge-std/Test.sol";

contract ProxyTest is Test {
    address private proxy;
    BoxV2 private boxV2;

    function setUp() public {
       DeployProxy deployProxy = new DeployProxy();
       proxy = deployProxy.run();
       boxV2 = new BoxV2();
    }

    function test_proxyDeployment() public view {
        uint256 version = BoxV1(proxy).version();
        assertEq(version, 1);
    }

    function test_upgradeWorks() public {
        Upgrade upgrade = new Upgrade();
        upgrade.upgrade(proxy, address(boxV2));
        uint256 version = BoxV2(proxy).version();
        assertEq(version, 2);
    }
}