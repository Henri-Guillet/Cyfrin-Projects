// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20MockFailedTransferFrom is ERC20 {
    constructor(
        address initialAccount,
        uint256 initialBalance
    )
        payable
        ERC20("mock", "mock")
    {
        _mint(initialAccount, initialBalance);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function transferInternal(address from, address to, uint256 value) public {
        _transfer(from, to, value);
    }

    function approveInternal(address owner, address spender, uint256 value) public {
        _approve(owner, spender, value);
    }


    function transferFrom(address /*from*/, address /*to*/, uint256 /*value*/) public pure override returns (bool) {
        return false;
    }
}