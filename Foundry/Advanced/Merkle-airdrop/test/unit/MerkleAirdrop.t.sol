// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {BagelToken} from "src/BagelToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";

contract MerkleAirdropTest is Test {
    BagelToken private bagel;
    MerkleAirdrop private merkleAirdrop;

    bytes32 private root = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address private gasPayer = makeAddr("gasPayer");
    address private user;
    uint256 private userPrivKey;
    uint256 private amountToCollect = (25 * 1e18);
    uint256 private amountToSend = amountToCollect * 4;
    bytes32 private proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 private proof2 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private proof = [proof1, proof2];

    function setUp() public {
        bagel = new BagelToken();
        merkleAirdrop = new MerkleAirdrop(address(bagel), root);
        (user, userPrivKey) = makeAddrAndKey("user");
        bagel.mint(address(merkleAirdrop), amountToSend);
    }

    function signMessage(uint256 privateKey, bytes32 digest) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        (v, r, s) = vm.sign(privateKey, digest);
    }

    function test_userCanClaim() public {
        //Arrange
        uint256 startingBalance = bagel.balanceOf(user);
        bytes32 digest = merkleAirdrop.getDigest(user, amountToCollect);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivKey, digest);

        //Act
        merkleAirdrop.claim(user, amountToCollect, proof, v, r, s);

        //Assert
        uint256 endingBalance = bagel.balanceOf(user);
        assertEq(endingBalance, startingBalance + amountToCollect);
    }
}
