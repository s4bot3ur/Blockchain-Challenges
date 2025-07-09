// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./DeathStar.sol";
import "./DarksidePool.sol";

contract Setup {
    DeathStar public deathStar;
    DarksidePool public darksidePool;

    constructor() payable {
        require(msg.value == 20 ether, "Setup requires 20 ETH");

        
        deathStar = new DeathStar();
        (bool success1, ) = address(deathStar).call{value: 10 ether}("");
        require(success1, "Failed to fund DeathStar");

       
        darksidePool = new DarksidePool(address(deathStar));
        (bool success2, ) = address(darksidePool).call{value: 10 ether}("");
        require(success2, "Failed to fund DarksidePool");

       
        require(address(deathStar).balance > 0, "DeathStar must have initial balance");
    }

    function isSolved() external view returns (bool) {
        return address(deathStar).balance == 0;
    }
}
