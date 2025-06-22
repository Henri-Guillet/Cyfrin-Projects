// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { GoldToken } from "./GoldToken.sol";
import { Test } from "forge-std/Test.sol";

contract GoldTokenTest is Test {
    GoldToken goldToken;

    function setUp() public {
        goldToken = new GoldToken(1000);
    }

    function testToTalSupply() public view {
        assertEq(goldToken.totalSupply(), 1000);
    }

}