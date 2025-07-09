// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./challenge.sol";

contract Setup {

    Challenge public challenge;
    
    constructor() payable{
        challenge = new Challenge();
    }
    
    function isSolved() external view returns (bool) {
        return challenge.solved();
    }
}