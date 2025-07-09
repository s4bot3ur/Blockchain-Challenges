// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "@openzeppelin/access/Ownable.sol";

contract Recovery is Ownable{
    bool public solved;

    constructor() Ownable(msg.sender) {
        solved = false;
    }

    /**
     * Only the owner can solve the challenge.
     */
    function solve() external onlyOwner{
        solved = true;
    }

    /**
     * Is the challenge solved ?
    */
    function isSolved() public returns (bool) {
        return solved;
    }

    /**
     * @dev Change owner
     * @param v signature of the hash
     * @param r signature of the hash
     * @param s signature of the hash
     * @param hash hash of the message authenticating the new owner
     * @param newOwner address of the new owner
     */
    function changeOwner(uint8 v, bytes32 r, bytes32 s, bytes32 hash, address newOwner) public {
        require(newOwner != address(0), "New owner should not be the zero address");
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner(), "New owner should have been authenticated");
        _transferOwnership(newOwner);
    }
}
