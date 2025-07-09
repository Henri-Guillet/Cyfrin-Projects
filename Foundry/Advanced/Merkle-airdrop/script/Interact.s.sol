// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {BagelToken} from "src/BagelToken.sol";

contract ClaimAirdrop is Script {
    address private constant SIGNER_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // signer's address which is anvil default
    uint256 private constant AMOUNT_TO_COLLECT = 25 * 1e18;
    bytes32 private proof1 = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 private proof2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private proof = [proof1, proof2];
    uint256 private signerBalance;
    uint8 v = 28;
    bytes32 r = 0x04209f8dfd0ef06724e83d623207ba8c33b6690e08772f8887a4eaf9a66b9182;
    bytes32 s = 0x188938adea374fa542ad5ddde24bdc981f5e26a628e65fb425a68db8a938f676;


    function claimAirdrop(address _contract) public {
        MerkleAirdrop merkleAirdrop = MerkleAirdrop(_contract);
        BagelToken token = BagelToken(address(merkleAirdrop.getAirdropToken()));
        signerBalance = token.balanceOf(SIGNER_ADDRESS);
        console2.log("Initial Balance of ", SIGNER_ADDRESS, " is ", signerBalance);

        //claim airdrop
        vm.startBroadcast();
        merkleAirdrop.claim(SIGNER_ADDRESS, AMOUNT_TO_COLLECT, proof, v, r, s);
        vm.stopBroadcast();
        signerBalance = token.balanceOf(SIGNER_ADDRESS);
        console2.log("Ending Balance of ", SIGNER_ADDRESS, " is ", signerBalance);        
    }

    function run() public {
        address merkleAirdropAddress = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(address(merkleAirdropAddress));
    }
}

contract SignMessage is Script {
    uint256 private constant AMOUNT_TO_COLLECT = 25 * 1e18;

    function signMessage(address _contract) public view returns(uint8 v, bytes32 r, bytes32 s) {
        MerkleAirdrop merkleAirdrop = MerkleAirdrop(_contract);
        //Sign message
        bytes32 digest = merkleAirdrop.getDigest(msg.sender, AMOUNT_TO_COLLECT);
        console2.log("Signer Address:", msg.sender);
        (v, r, s) = vm.sign(digest);
    }

    function run() public view returns(uint8 v, bytes32 r, bytes32 s){
        address merkleAirdropAddress = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        (v, r, s) = signMessage(address(merkleAirdropAddress));
    }
}