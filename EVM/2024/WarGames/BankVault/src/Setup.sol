// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./BankVaults.sol";
import {MockERC20} from "./MockERC20.sol";
contract Setup {
    BankVaults public challengeInstance;

    constructor() payable {
        require(msg.value == 50 ether, "Setup requires exactly 50 ETH to initialize the challenge");

        
        MockERC20 mockERC20 = new MockERC20(1_000_000 ether);

        // Step 2: Deploy the BankVaults contract with the MockERC20 address
        challengeInstance = new BankVaults{value: 50 ether}(IERC20(address(mockERC20)));
    }

    function isSolved() public view returns (bool) {
        // The challenge is solved if the ETH balance of the BankVaults contract is 0
        return address(challengeInstance).balance == 0;
    }
}