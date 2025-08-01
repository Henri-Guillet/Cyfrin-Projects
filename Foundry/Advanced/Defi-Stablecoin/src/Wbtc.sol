// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Wbtc is ERC20{
    constructor() ERC20("Wrapped Bitcoin", "WBTC"){
        _mint(msg.sender, type(uint256).max);
    }

}