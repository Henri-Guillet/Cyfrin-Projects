// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {BagelToken} from "src/BagelToken.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4; 
    uint256 private constant AMOUNT_TO_COLLECT = (25 * 1e18);
    uint256 private constant AMOUNT_TO_SEND = AMOUNT_TO_COLLECT * 4;

    function deployMerkleAirdrop() public {
        vm.startBroadcast();
        BagelToken token = new BagelToken();
        console2.log("Bagel Token deployed at", address(token));
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(address(token), ROOT);
        console2.log("Merkle contract deployed at", address(merkleAirdrop));
        token.mint(address(merkleAirdrop), AMOUNT_TO_SEND);
        console2.log("Balance of merkle contract is", token.balanceOf(address(merkleAirdrop)));
        vm.stopBroadcast();
    }
    
    function run() public {
        deployMerkleAirdrop();
    }
}