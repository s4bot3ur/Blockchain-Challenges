pragma solidity ^0.8.20;

import "./GuessIt.sol";

contract Setup {
    EasyChallenge public challengeInstane;

    constructor() {
        challengeInstane = new EasyChallenge();
    }

    function isSolved() public view returns (bool) {
        return challengeInstane.isKeyFound(); 
    }
}