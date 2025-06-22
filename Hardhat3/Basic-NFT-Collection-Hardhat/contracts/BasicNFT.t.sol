// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BasicNFT} from "./BasicNFT.sol";
import { Test } from "forge-std/Test.sol";

contract BasicNFTTest is Test {
    BasicNFT public basicNFT;
    string public name = "Dogie";
    string public symbol = "DOG";
    string public constant PUG_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    address public constant USER = address(1);

    function setUp () public {
        basicNFT = new BasicNFT();
    }

    function testNames() public view {
        assert(keccak256(abi.encodePacked(basicNFT.name())) == keccak256(abi.encodePacked(name)));
        assert(keccak256(abi.encodePacked(basicNFT.symbol())) == keccak256(abi.encodePacked("DOG")));
    }

    function testCanMint() public {
        vm.prank(USER);
        basicNFT.mint(PUG_URI);
        assert(basicNFT.balanceOf(USER) == 1);
    }

    function testTokenURIIsCorrect() public {
        vm.prank(USER);
        basicNFT.mint(PUG_URI);
        assert(keccak256(abi.encodePacked(basicNFT.tokenURI(0))) == keccak256(abi.encodePacked(PUG_URI)));
    }
}
