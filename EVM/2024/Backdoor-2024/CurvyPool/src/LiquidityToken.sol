// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC20.sol";

contract LiquidityToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
}