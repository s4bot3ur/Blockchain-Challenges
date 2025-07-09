pragma solidity ^0.8.20;

contract EasyChallenge {
    uint constant isKey = 0x1337;

    bool public isKeyFound;
    mapping (uint => bytes32) keys; 

    constructor() {
        keys[isKey] = keccak256(
            abi.encodePacked(block.number, msg.sender) 
        );
    }

    function unlock(uint slot) external {
        bytes32 key;
        assembly {
            key := sload(slot)
        }
        require(key == keys[isKey]);
        isKeyFound = true;
    }
}