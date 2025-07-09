// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MerkleAirdrop__NotEligible();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    /*//////////////////////////////////////////////////////////////
                                 LIBRAIRIES
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IERC20 private immutable i_token;
    bytes32 private immutable i_root;
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");
    mapping(address user => bool) s_hasClaimed;

    /*//////////////////////////////////////////////////////////////
                                 EVENT
    //////////////////////////////////////////////////////////////*/
    event Claimed(address indexed account, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address token, bytes32 root) EIP712("Merkle Airdrop", "1.0.0") {
        i_root = root;
        i_token = IERC20(token);
    }

    // claim the airdrop using a signature from the account owner   
    function claim(address account, uint256 amount, bytes32[] calldata proof, uint8 v, bytes32 r, bytes32 s) external {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        if (!_isValidSignature(account, getDigest(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        bool verified = MerkleProof.verifyCalldata(proof, i_root, leaf);
        if (!verified) {
            revert MerkleAirdrop__NotEligible();
        }
        s_hasClaimed[account] = true;
        emit Claimed(account, amount);
        i_token.safeTransfer(account, amount);
    }

    function getDigest(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, account, amount)));
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _isValidSignature(address signer, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        private
        pure
        returns (bool)
    {
        (address recovered,,) = ECDSA.tryRecover(digest, v, r, s);
        return (recovered == signer);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    function getMerkleRoot() external view returns (bytes32) {
        return i_root;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_token;
    }
}
