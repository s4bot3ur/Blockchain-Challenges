// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./DungeonsNDragons.sol";

contract Setup {
    DungeonsAndDragons public challengeInstance;

    constructor(string memory _salt, uint256 _initialReward, uint256 _initialLevel) payable {
        
        require(msg.value == 100 ether, "Setup requires exactly 100 ETH for the challenge");
        challengeInstance = new DungeonsAndDragons{value: msg.value}(_salt, _initialReward, _initialLevel);
    }

    
    function isSolved() public view returns (bool) {
        
        return address(challengeInstance).balance == 0;
    }
}
