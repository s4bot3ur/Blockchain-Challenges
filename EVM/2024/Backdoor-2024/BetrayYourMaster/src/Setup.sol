// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Challenge.sol";

contract Setup {
    address public immutable master;
    Treasury public treasury;
    SecretChecker public secretChecker;

    constructor() payable {
        master = msg.sender;
        treasury = new Treasury{value : 1 ether}(msg.sender);
        secretChecker = new SecretChecker();
    }

    function isSolved() public returns (bool) {
        (bool MasterCanWithdraw, ) = address(treasury).call{gas : 1000000}(abi.encodeWithSignature("withdraw()"));
        bool IKnowTheSecret = secretChecker.SecretIsLeaked();  
        return (!MasterCanWithdraw) && IKnowTheSecret;   
    }    

    receive() external payable {}
}